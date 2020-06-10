=<template>
  <div id="peervideo">
    <h3>added: {{ addedStream }}</h3>
    <h3>sent: {{ sentCam }}</h3>
    <video
      ref="remoteVideo"
      id="remoteVideo"
      v-bind:class="{ robot: sendCam, remote: !sendCam }"
      width="640"
      height="320"
      autoplay
      playsinline
    ></video>
  </div>
</template>

<script>
import adapter from "webrtc-adapter";

adapter;

export default {
  name: "PeerVideo",
  props: {
    sendCam: Boolean
  },
  data() {
    return {
      addedStream: false,
      sentCam: false
    };
  },
  computed: {
    peerConn() {
      return this.$store.state.peerConn;
    }
  },
  created() {
    this.unsubscribe = this.$store.subscribe((mutation, state) => {
      if (mutation.type == "setPeerConn") {
        this.watchVideo(state.peerConn);
        state.peerConn.onconnectionstatechange = () =>
          this.watchVideo(state.peerConn);
      }
    });
  },
  methods: {
    async watchVideo(peerConn) {
      if (peerConn) {
        let inboundStream = null;
        let videoElem = this.$refs.remoteVideo;
        peerConn.ontrack = ev => {
          if (ev.streams && ev.streams[0]) {
            console.log("AddedStream");
            videoElem.srcObject = ev.streams[0];
            this.addedStream = true;
          } else {
            if (!inboundStream) {
              console.log("Added track");
              inboundStream = new MediaStream();
              videoElem.srcObject = inboundStream;
              this.addedStream = true;
            }
            inboundStream.addTrack(ev.track);
          }
        };
        console.log("added peerConn ontrack");
      }
    }
  }
};
</script>

<style scoped>
video.remote {
  width: auto;
  height: 50%;
}
video.robot {
  width: 100%;
  height: auto;
}
</style>
