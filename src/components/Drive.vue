<template>
  <div id="drive">
    <v-slider
      label="left"
      persistent-hint
      v-model="driveleft"
      min="26"
      max="128"
      v-on:change="drive"
    />
    <v-slider
      label="right"
      persistent-hint
      v-model="driveright"
      min="26"
      max="128"
      v-on:change="drive"
    />
    <v-btn @click="forwardClicked">forward</v-btn>
    <v-btn @click="backwardClicked">backward</v-btn>
    <v-btn @click="leftClicked">left</v-btn>
    <v-btn @click="rightClicked">right</v-btn>
    <v-btn @click="stopClicked">stop</v-btn>
    <v-btn id="find" @click="findClicked">find</v-btn>
    <div style="white-space: pre;">{{ logdata }}></div>
  </div>
</template>

<script>
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
  name: "Drive",
  props: {
    msg: String,
  },
  data() {
    return {
      logdata: "",
      device: null,
      services: null,
      driveleft: 76,
      driveright: 76,
      drivemin: BACKWARD,
      drivemax: FORWARD,
    };
  },
  created() {
    this.mqttclient = mqtt.connect(MQTT_URL, {
      clientId: "robophone",
      clean: true,
      username: "roboLucas",
    });
    this.mqttclient.subscribe("robophone_drive", { qos: 1 });
    this.mqttclient.on("message", this.onMessage);
  },
  methods: {
    async onMessage(topic, message, packet) {
      this.log("message is " + message);
      this.log("topic is " + topic);
      this.log("packet is " + packet);
      if (message == "driveleft") {
        this.leftClicked();
      } else if (message == "driveright") {
        this.rightClicked();
      } else if (message == "driveforward") {
        this.forwardClicked();
      } else if (message == "drivebackward") {
        this.backwardClicked();
      }
    },
    log(message) {
      this.logdata += message + "\n";
    },
    logJson(message) {
      this.log(JSON.stringify(message, null, 2));
    },
    eventHandler(event) {
      this.log(`${event.type}: ${JSON.stringify(event.detail, null, 2)}`);
    },
    async changeleft() {
      this.log("changeleft: " + this.driveleft + " : " + this.driveright);
      this.drive(this.driveleft, this.driveright);
    },
    async changeright() {
      this.log("changeright: " + this.driveleft + " : " + this.driveright);
      this.drive(this.driveleft, this.driveright);
    },
    async drive() {
      if (!this.device) {
        this.device = await requestMicrobit(window.navigator.bluetooth);
        this.services = await getServices(this.device);
      }

      if (this.device) {
        const period = 20000;

        this.log("drive: " + this.driveleft + " : " + this.driveright);
        this.services.ioPinService.setPwmControl({
          pin: LEFT_PIN,
          value: this.driveleft,
          period: period,
        });
        this.services.ioPinService.setPwmControl({
          pin: RIGHT_PIN,
          value: this.driveright,
          period: period,
        });
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

        this.log("stop: " + this.driveleft + " : " + this.driveright);
        await this.services.ioPinService.setPwmControl({
          pin: LEFT_PIN,
          value: 0,
          period: period,
        });
        await this.services.ioPinService.setPwmControl({
          pin: RIGHT_PIN,
          value: 0,
          period: period,
        });
      }
    },
    async forwardClicked() {
      this.driveleft = FORWARD;
      this.driveright = BACKWARD;
      this.drive();
    },
    async backwardClicked() {
      this.driveleft = BACKWARD;
      this.driveright = FORWARD;
      this.drive();
    },
    async leftClicked() {
      this.driveleft = BACKWARD;
      this.driveright = BACKWARD;
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
    async findClicked() {
      if (!this.device) {
        this.device = await requestMicrobit(window.navigator.bluetooth);
        this.services = await getServices(this.device);
      }
      if (this.device) {
        //const services = await getServices(this.device);

        if (this.services.deviceInformationService) {
          this.logJson(
            await this.services.deviceInformationService.readDeviceInformation()
          );
        }

        if (this.services.uartService) {
          this.services.uartService.addEventListener(
            "receiveText",
            this.eventHandler
          );
          await this.services.uartService.send(
            new Uint8Array([104, 101, 108, 108, 111, 58])
          ); // hello:
        }

        if (this.services.ledService) {
          await this.services.ledService.writeMatrixState([
            [1, 0, 1, 0, 0],
            [1, 1, 1, 1, 1],
            [0, 0, 1, 0, 0],
            [0, 1, 0, 1, 0],
            [1, 0, 0, 0, 1],
          ]);
          this.logJson(await this.services.ledService.readMatrixState());

          await this.services.ledService.setScrollingDelay(50);
          this.log(await this.services.ledService.getScrollingDelay());

          await this.services.ledService.writeText("Web BLE");
        }

        if (this.services.buttonService) {
          this.services.buttonService.addEventListener(
            "buttonastatechanged",
            this.eventHandler
          );
          this.services.buttonService.addEventListener(
            "buttonbstatechanged",
            this.eventHandler
          );
        }

        if (this.services.temperatureService) {
          await this.services.temperatureService.setTemperaturePeriod(2000);
          this.log(
            await this.services.temperatureService.getTemperaturePeriod()
          );
          this.services.temperatureService.addEventListener(
            "temperaturechanged",
            this.eventHandler
          );
        }

        if (this.services.accelerometerService) {
          await this.services.accelerometerService.setAccelerometerPeriod(640);
          this.log(
            await this.services.accelerometerService.getAccelerometerPeriod()
          );
          this.services.accelerometerService.addEventListener(
            "accelerometerdatachanged",
            this.eventHandler
          );
        }

        if (this.services.magnetometerService) {
          const startMagnetometer = async () => {
            await this.services.magnetometerService.setMagnetometerPeriod(640);
            this.log(
              await this.services.magnetometerService.getMagnetometerPeriod()
            );

            this.services.magnetometerService.addEventListener(
              "magnetometerdatachanged",
              this.eventHandler
            );
            this.services.magnetometerService.addEventListener(
              "magnetometerbearingchanged",
              this.eventHandler
            );
          };

          this.services.magnetometerService.addEventListener(
            "magnetometercalibrationchanged",
            async (response) => {
              if (response.detail === 2) {
                await startMagnetometer();
              }
            }
          );

          try {
            await this.services.magnetometerService.calibrate();
          } catch (e) {
            await startMagnetometer();
          }
        }
      }
    },
  },
};
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
