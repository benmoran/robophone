<template>
  <div id="peerconnect">
    <v-btn v-if="!connected" :disabled="socket != null" @click="connect"
      >Connect</v-btn
    >
    <ul>
      <li>Client id: {{ clientId }}</li>
      <li>isInitiator: {{ isInitiator }}</li>
      <li>peerConn: {{ peerConn }}</li>
      <li>connectionState: {{ connectionState }}</li>
    </ul>

    <div id="divLog">
      <pre>
        {{ logdata }}
      </pre>
    </div>
  </div>
</template>

<script>
import adapter from "webrtc-adapter";
import io from "socket.io-client";
adapter;

function logError(err) {
  if (!err) return;
  if (typeof err === "string") {
    console.warn(err);
  } else {
    console.warn(err.toString(), err);
  }
}

export default {
  name: "PeerConnect",
  props: {},
  data() {
    return {
      logdata: "",
      room: "robophone",
      clientId: null,
      socket: null,
      isInitiator: false,
      dataChannel: null,
      configuration: {
        iceServers: [
          {
            url: "turn:YOUR_COTURN_PUBLIC_IP:3478?transport=udp",
            credential: "YOUR_COTURN_CREDENTIALS=",
            username: "YOUR_COTORN_USERNAME",
          },
          { urls: "stun:stun.l.google.com:19302" },
        ],
      },
      offerOptions: {
        offerToReceiveAudio: 1,
        offerToReceiveVideo: 1,
      },
    };
  },
  computed: {
    peerConn() {
      return this.$store.state.peerConn;
    },
    connectionState() {
      return this.peerConn ? this.peerConn.connectionState : null;
    },
    connected() {
      return this.socket != null && this.socket.connected;
    },
  },
  created() {},
  methods: {
    onDataChannelCreated(channel) {
      this.$store.commit("setDataChannel", channel);
      console.log("onDataChannelCreated:", channel);

      channel.onopen = () => {
        console.log("CHANNEL opened!!!");
        //sendBtn.disabled = false;
        //snapAndSendBtn.disabled = false;
      };

      channel.onclose = () => {
        console.log("Channel closed.");
        //sendBtn.disabled = true;
        //snapAndSendBtn.disabled = true;
      };

      // channel.onmessage = (adapter.browserDetails.browser === 'firefox') ?
      //     this.receiveDataFirefoxFactory() : this.receiveDataChromeFactory();
    },
    connect() {
      // Connect to the signaling server
      //const socket = this.socket = io("http://gigabyte:8083"); //, {transports: ["websocket"]});
      const socket = (this.socket = io()); // default to this website

      socket.on("ipaddr", (ipaddr) => {
        console.log("Server IP address is: " + ipaddr);
        //updateRoomURL(ipaddr);
      });

      socket.on("created", (room, clientId) => {
        this.clientId = clientId;
        console.log("Created room", room, "- my client ID is", clientId);
        this.isInitiator = true;
        //grabWebCamVideo();
      });

      socket.on("joined", (room, clientId) => {
        this.clientId = clientId;
        console.log(
          "This peer has joined room",
          room,
          "with client ID",
          clientId
        );
        this.isInitiator = false;
        this.createPeerConnection(this.isInitiator, this.offerOptions);
        //grabWebCamVideo();
      });

      socket.on("full", (room) => {
        alert("Room " + room + " is full.");
        //window.location.hash = '';
        //window.location.reload();
      });

      socket.on("ready", () => {
        console.log("Socket is ready");
        this.createPeerConnection(this.isInitiator, this.configuration);
      });

      socket.on("log", (array) => {
        console.log.apply(console, array);
      });

      socket.on("message", (message) => {
        //console.log('Client received message:', message);
        this.signalingMessageCallback(message);
      });

      // Joining a room.
      socket.emit("create or join", this.room);

      if (location.hostname.match(/localhost|127\.0\.0/)) {
        socket.emit("ipaddr");
      }

      // Leaving rooms and disconnecting from peers.
      socket.on("disconnect", (reason) => {
        console.log(`Disconnected: ${reason}.`);
        //sendBtn.disabled = true;
        //snapAndSendBtn.disabled = true;
      });

      socket.on("bye", (room) => {
        console.log(`Peer leaving room ${room}.`);
        //sendBtn.disabled = true;
        //snapAndSendBtn.disabled = true;
        // If peer did not create the room, re-enter to be creator.
        if (!this.isInitiator) {
          window.location.reload();
        }
      });

      window.addEventListener("unload", () => {
        console.log(`Unloading window. Notifying peers in ${this.room}.`);
        socket.emit("bye", this.room);
      });
    },
    signalingMessageCallback(message) {
      if (!message) {
        console.log("signalingMessageCallback with no message");
        return;
      }
      if (message.type === "offer") {
        console.log("Got offer. Sending answer to peer.");
        this.peerConn.setRemoteDescription(
          new RTCSessionDescription(message),
          () => {},
          console.log
        );
        this.peerConn.createAnswer(this.onLocalSessionCreated, logError);
      } else if (message.type === "answer") {
        console.log("Got answer.");
        this.peerConn.setRemoteDescription(
          new RTCSessionDescription(message),
          () => {},
          console.log
        );
      } else if (message.type === "candidate") {
        this.peerConn.addIceCandidate(
          new RTCIceCandidate({
            candidate: message.candidate,
            sdpMLineIndex: 0, // TODO: needed to add?
            usernameFragment: null, // TODO: needed to add? does it help in firefox?
          })
        );
      }
    },
    createPeerConnection(isInitiator, config) {
      console.log(
        "Creating Peer connection as initiator?",
        isInitiator,
        "config:",
        config,
        "this",
        this
      );
      this.$store.commit("setPeerConn", new RTCPeerConnection(config));

      // send any ice candidates to the other peer
      this.peerConn.onicecandidate = (event) => {
        //console.log('icecandidate event:', event);
        if (event.candidate) {
          this.sendMessage({
            type: "candidate",
            label: event.candidate.sdpMLineIndex,
            id: event.candidate.sdpMid,
            candidate: event.candidate.candidate,
          });
        } else {
          console.log("End of candidates.");
        }
      };

      if (isInitiator) {
        console.log("Creating Data Channel", this.peerConn);
        this.dataChannel = this.peerConn.createDataChannel("data", {
          ordered: false,
          maxPacketLifeTime: 1000,
        });
        this.onDataChannelCreated(this.dataChannel);

        console.log("Creating an offer");
        this.peerConn.createOffer(
          this.onLocalSessionCreated,
          logError,
          this.configuration
        ); // does this help
      } else {
        this.peerConn.ondatachannel = (event) => {
          console.log("ondatachannel:", event.channel);
          this.dataChannel = event.channel;
          this.onDataChannelCreated(this.dataChannel);
        };
      }
    },

    onLocalSessionCreated(desc) {
      console.log("local session created:", desc);
      this.peerConn.setLocalDescription(
        desc,
        () => {
          console.log("sending local desc:", this.peerConn.localDescription);
          this.sendMessage(this.peerConn.localDescription);
        },
        logError
      );
    },
    sendMessage(message) {
      //console.log('Client sending message: ', message);
      this.socket.emit("message", message);
    },

    log(message) {
      this.logdata += message + "\n";
    },
    logJson(message) {
      this.log(JSON.stringify(message, null, 2));
    },
  },
};
</script>

<style scoped></style>
