<template>
<div id="localdrive">
  <h1>Local</h1>

  <h2 v-if="receiving">RECEIVING</h2>
    <v-btn v-if="needConnection" id="find" @click="findClicked">find</v-btn>
    <div style="white-space: pre">{{logdata}}></div>
    <div v-if="!needConnection">Temp: {{temperature}}</div>
</div>
</template>

<script>

import { requestMicrobit, getServices } from  "microbit-web-bluetooth/dist/microbit.umd.js"

// PWM duty cycle values.
// Fraction of a 20000us = 20ms period, with 1023 = 100%.
// 20000 * 76/1024 = 1485us ~ 1.5ms, the central "stop" position for typical servos.
// 0.5ms - 2.5ms range of duty cycles goes from full backward to full forward.

const BACKWARD = 26; 
const STOP = 76;
const FORWARD = 128;

const LEFT_PIN = 0;
const RIGHT_PIN = 2;



export default {
    name: 'LocalDrive',
    props: {
    },
    data() {
        return {
            logdata: '',
            device: null,
            services: null,
            driveleft: 76,
            driveright: 76,
            drivemin: BACKWARD,
            drivemax: FORWARD,
            receiving: false,
            temperature: null,

        }
    },
    computed: {
        needConnection() {
            return !this.device;
        }
    },
    created() {       
        this.unsubscribe = this.$store.subscribe((mutation, state) => {
            console.log("LocalDrive subscribe to store");
            if (mutation.type == 'setDataChannel') {
                console.log("LocalDrive subscribe to store setDataChannel");                
                this.setDataChannel(state);
            }});
        setTimeout(()=>this.setDataChannel(this.$store.state), 500);
    },
    methods: {
        setDataChannel(state) {
            if (state.dataChannel != null) {
                var receiveChannel = state.dataChannel;
                this.receiving = receiveChannel.readyState == "open";
                receiveChannel.onmessage = this.handleReceiveMessage;
                receiveChannel.onopen = this.handleReceiveChannelStatusChange;
                receiveChannel.onclose = this.handleReceiveChannelStatusChange;                
            } else {
                this.receiving = false;
            }
        },
        // receiveChannelCallback() { //event.channel
        //     var receiveChannel = this.$store.state.dataChannel;
        //     this.receiving = receiveChannel.readyState;            
        //     receiveChannel.onmessage = this.handleReceiveMessage;
        //     receiveChannel.onopen = handleReceiveChannelStatusChange;
        //     receiveChannel.onclose = handleReceiveChannelStatusChange;
        // },
        async handleReceiveChannelStatusChange() {
            console.log("handleReceiveChannelStatusChange");
            this.receiving = this.$store.state.dataChannel.readyState == "open";
        },
        async handleReceiveMessage(event) {
            this.logJson(event.data);            
            var message = JSON.parse(event.data);
            this.driveleft = message.left;
            this.driveright = message.right;
            this.drive();            
        },
        log(message) {this.logdata += message + "\n"},
        logJson(message) {this.log(JSON.stringify(message, null, 2))},
        eventHandler(event) {
            if (event.type == 'temperaturechanged') {
                this.temperature = event.detail;
            }
            
            //this.log(`${event.type}: ${JSON.stringify(event.detail, null, 2)}`)
        },
        async drive() {
            if (!this.device) {
                this.device = await requestMicrobit(window.navigator.bluetooth);
                this.services = await getServices(this.device);
            }

            if (this.device) {
                const period = 20000;

                this.log("drive: " + this.driveleft +" : " + this.driveright);
                this.services.ioPinService.setPwmControl({pin:LEFT_PIN, value:this.driveleft, period: period});
                this.services.ioPinService.setPwmControl({pin:RIGHT_PIN, value:this.driveright, period: period});
                setTimeout(this.stopClicked, 500);
            }
        },
        async stopClicked() {
            if (!this.device) {
                this.device = await requestMicrobit(window.navigator.bluetooth);
                this.services = await getServices(this.device);
            }
            if (this.device) {
                const period = 20000;

                this.log("stop: " + this.driveleft +" : " + this.driveright);
                await this.services.ioPinService.setPwmControl({pin:LEFT_PIN, value: 0, period: period});
                await this.services.ioPinService.setPwmControl({pin:RIGHT_PIN, value: 0, period: period});
            }
        },
        async forwardClicked() {
            this.driveleft = FORWARD;
            this.driveright = BACKWARD;
            this.drive();
        },
        async backwardClicked() {
            this.driveleft =  BACKWARD;
            this.driveright = FORWARD;
            this.drive();
        },
        async leftClicked() {
            this.driveleft =  BACKWARD;
            this.driveright =  BACKWARD;
            this.drive();
        },
        async rightClicked() {
            this.driveleft = FORWARD;
            this.driveright = FORWARD;
            this.drive();
        },

        async stopClicked1() {
            this.driveleft = STOP;
            this.driveright = STOP;

            this.drive();
        },
        async findClicked () {
            if (!this.device) {
                this.device = await requestMicrobit(window.navigator.bluetooth);
                this.services = await getServices(this.device);
            }
            if (this.device) {
                //const services = await getServices(this.device);

                if (this.services.deviceInformationService) {
                    this.logJson(await this.services.deviceInformationService.readDeviceInformation());
                }

                if (this.services.uartService) {
                    this.services.uartService.addEventListener("receiveText", this.eventHandler);
                    await this.services.uartService.send(new Uint8Array([104, 101, 108, 108, 111, 58])); // hello:
                }

                if (this.services.ledService) {
                    await this.services.ledService.writeMatrixState([
                        [1, 0, 1, 0, 0],
                        [1, 1, 1, 1, 1],
                        [0, 0, 1, 0, 0],
                        [0, 1, 0, 1, 0],
                        [1, 0, 0, 0, 1]
                    ]);
                    this.logJson(await this.services.ledService.readMatrixState());

                    await this.services.ledService.setScrollingDelay(50);
                    this.log(await this.services.ledService.getScrollingDelay());

                    await this.services.ledService.writeText("Web BLE");
                }

                if (this.services.buttonService) {
                    this.services.buttonService.addEventListener("buttonastatechanged", this.eventHandler);
                    this.services.buttonService.addEventListener("buttonbstatechanged", this.eventHandler);
                }

                if (this.services.temperatureService) {
                    await this.services.temperatureService.setTemperaturePeriod(2000);
                    this.log(await this.services.temperatureService.getTemperaturePeriod());
                    this.services.temperatureService.addEventListener("temperaturechanged", this.eventHandler);
                }

                if (this.services.accelerometerService) {
                    await this.services.accelerometerService.setAccelerometerPeriod(640);
                    this.log(await this.services.accelerometerService.getAccelerometerPeriod());
                    this.services.accelerometerService.addEventListener("accelerometerdatachanged", this.eventHandler);
                }

                if (this.services.magnetometerService) {
                    const startMagnetometer = async () => {
                        await this.services.magnetometerService.setMagnetometerPeriod(640);
                        this.log(await this.services.magnetometerService.getMagnetometerPeriod());

                        this.services.magnetometerService.addEventListener("magnetometerdatachanged", this.eventHandler);
                        this.services.magnetometerService.addEventListener("magnetometerbearingchanged", this.eventHandler);
                    };

                    this.services.magnetometerService.addEventListener("magnetometercalibrationchanged", async response => {
                        if (response.detail === 2) {
                                await startMagnetometer();
                            }
                        });

                        try {
                            await this.services.magnetometerService.calibrate();
                        } catch (e) {
                            await startMagnetometer();
                        }
                    }
                }
        },

    }
}








</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
h3 {
    margin: 40px 0 0;
}
ul {
    list-style-type: none;
  padding: 0;
}
li {
  display: inline-block;
  margin: 0 10px;
}
a {
  color: #42b983;
}
</style>


