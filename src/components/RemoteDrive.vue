=<template>
  <div id="remotedrive">
    <span v-hotkey.prevent="keymap" v-show="show">
      Press `ctrl + esc` to toggle me! Hold `enter` to hide me!
    </span>

    <v-slider
      :disabled="!haveDataConnection"
      label="left"
      persistent-hint
      v-model="driveleft"
      min="26"
      max="128"
      v-on:change="drive"
    />
    <v-slider
      :disabled="!haveDataConnection"
      label="right"
      persistent-hint
      v-model="driveright"
      min="26"
      max="128"
      v-on:change="drive"
    />
    <v-btn :disabled="!haveDataConnection" @click="forwardClicked"
      >forward</v-btn
    >
    <v-btn :disabled="!haveDataConnection" @click="backwardClicked"
      >backward</v-btn
    >
    <v-btn :disabled="!haveDataConnection" @click="leftClicked">left</v-btn>
    <v-btn :disabled="!haveDataConnection" @click="rightClicked">right</v-btn>
    <v-btn :disabled="!haveDataConnection" @click="stopClicked">stop</v-btn>
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

import VueHotkey from "v-hotkey";

import Vue from "vue";
Vue.use(VueHotkey);

export default {
  name: "RemoteDrive",
  props: {},
  data() {
    return {
      driveleft: 76,
      driveright: 76,
      drivemin: BACKWARD,
      drivemax: FORWARD,
      haveDataConnection: false
    };
  },
  computed: {
    keymap() {
      return {
        left: this.leftClicked,
        right: this.rightClicked,
        up: this.forwardClicked,
        down: this.backwardClicked
        //'enter': {
        // keydown: this.hide,
        //keyup: this.show
        // }
      };
    }
  },
  created() {
    this.haveDataConnection =
      this.$store.state.dataChannel &&
      this.$store.state.dataChannel.readyState == "open";
    this.unsubscribe = this.$store.subscribe((mutation, state) => {
      console.log("RemoteDrive subscribe to store");
      if (mutation.type == "setDataChannel") {
        console.log("RemoteDrive subscribe to store setDataChannel");
        this.setDataChannel(state);
      }
    });
    setTimeout(() => this.setDataChannel(this.$store.state), 500);
  },
  methods: {
    setDataChannel(state) {
      if (state.dataChannel != null) {
        var dataChannel = state.dataChannel;
        this.haveDataConnection = dataChannel.readyState == "open";
        //dataChannel.onmessage = this.handleReceiveMessage;
        dataChannel.onopen = this.handleSendChannelStatusChange;
        dataChannel.onclose = this.handleSendChannelStatusChange;
      } else {
        this.haveDataConnection = false;
      }
      setTimeout(() => this.setDataChannel(this.$store.state), 1000); // TODO unnecessary?
    },
    async handleSendChannelStatusChange() {
      this.haveDataConnection =
        this.$store.state.dataChannel.readyState == "open";
    },
    driveMessage() {
      return JSON.stringify({ left: this.driveleft, right: this.driveright });
    },
    drive() {
      var channel = this.$store.state.dataChannel;
      if (channel) {
        channel.send(this.driveMessage());
      } else {
        console.log("No data channel");
      }
    },
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
    async stopClicked() {
      this.driveleft = STOP;
      this.driveright = STOP;
      this.drive();
    }
  }
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
 {
  color: #42b983;
}
</style>
