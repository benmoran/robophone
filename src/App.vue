<template>
  <v-app>
    <button type="button" @click="toggle">Fullscreen</button>
    <fullscreen ref="fullscreen" @change="fullscreenChange">
      <RemoteDrive v-if="!isRobot" />
      <PeerVideo v-bind:sendCam="isRobot" />
    </fullscreen>
    <Face v-bind:faceImages="!isRobot" />

    <LocalDrive v-if="isRobot" />
    <PeerConnect />
  </v-app>
</template>

<script>
import LocalDrive from "./components/LocalDrive";
import RemoteDrive from "./components/RemoteDrive";
import PeerConnect from "./components/PeerConnect";
import PeerVideo from "./components/PeerVideo";
import Face from "./components/Face";

import fullscreen from "vue-fullscreen";
import Vue from "vue";
import Vuex from "vuex";

Vue.use(Vuex);

Vue.use(fullscreen);

const store = new Vuex.Store({
  state: {
    peerConn: null,
    pathname: "default",
    dataChannel: null,
  },
  mutations: {
    setDataChannel(state, dataChannel) {
      state.dataChannel = dataChannel;
    },
    setPeerConn(state, peerConn) {
      state.peerConn = peerConn;
    },
    setPathname(state, pathname) {
      state.pathname = pathname;
    },
  },
});

export default {
  name: "App",
  components: {
    LocalDrive,
    RemoteDrive,
    Face,
    PeerConnect,
    PeerVideo,
  },
  created() {
    store.commit("setPathname", window.location.pathname);
  },
  data() {
    return {
      uri: null,
      store: store,
      fullscreen: false,
    };
  },
  methods: {
    toggle() {
      this.$refs["fullscreen"].toggle(); // recommended
    },
    fullscreenChange(fullscreen) {
      this.fullscreen = fullscreen;
    },
  },
  computed: {
    isRobot() {
      return store.state.pathname == "/robot";
    },
  },
  store,
};
</script>
