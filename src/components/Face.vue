<template>
<div>
  <div class="inputVideo" style="position: relative">
      <video :srcObject="{stream}"
             ref="inputVideo"
             width="640"
             height="480"
             autoplay muted playsinline></video>
      
      <canvas ref="overlay" class="overlay"/>
</div>
  <canvas v-if="faceImages" width="240" height="320" ref="cropface"/>                  

</div>
</template>

<script>
import { mapState } from 'vuex'
//import PeerConnect from './PeerConnect';  
  const SSD_MOBILENETV1 = 'ssd_mobilenetv1';
  const TINY_FACE_DETECTOR = 'tiny_face_detector';
const faceWidth = 240;
const faceHeight = 320;

var faceapi = require('face-api.js');
//import { Box } from  "face-api.js/dist/face-api.js"




const adapter = require('webrtc-adapter');
//import adapter from 'webrtc-adapter';
adapter;
  export default {
      name: 'Face',
      props: {
          faceImages: Boolean,
      },
      data() {
          return {
              stream: null,
              selectedFaceDetector: TINY_FACE_DETECTOR,
              faceBox: new faceapi.Rect(faceHeight,20,faceHeight,faceWidth),
              faceWidth: faceWidth,
              faceHeight: faceHeight,
          }
      },
      computed: mapState([
          // map this.count to store.state.count
          'peerConn'
      ]),
      created() {
          this.run();
          this.unsubscribe = this.$store.subscribe((mutation, state) => {
              if (mutation.type == 'setPeerConn') {
                  if (state.peerConn != null) {
                      if (this.faceImages) {
                          var canvas = this.$refs.cropface;
                          canvas.getContext('2d'); // important to initialize for firefox
                          var canvasStream = canvas.captureStream();
                          
                          this.stream.getAudioTracks().forEach(function(track) {
                              state.peerConn.addTrack(track);
                          });
                          canvasStream.getVideoTracks().forEach(function(track) {
                              state.peerConn.addTrack(track);
                          });
                      } else {
                          this.stream.getAudioTracks().forEach(function(track) {
                              state.peerConn.addTrack(track);
                          });
                          this.stream.getVideoTracks().forEach(function(track) {
                              state.peerConn.addTrack(track);
                          });
                          
                      }

                      //state.peerConn.addStream(canvas.captureStream(25));                      
                      //var videoEl = this.$refs.inputVideo;
                      //state.peerConn.addStream(videoEl.srcObject);
                      
                  }
              }
          });
      },
                                                   
      methods: {
          async run() {
              if (this.faceImages) {              
                  await this.getCurrentFaceDetectionNet().load('/facemodels')
              }
              this.stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
              var videoEl = this.$refs.inputVideo;
              videoEl.srcObject = this.stream;
              if (this.faceImages) {
                  setTimeout(this.onPlay, 500);   // needed to make this a bit longer on phone - how to make it reliable?
              }
          },

          getCurrentFaceDetectionNet() {
              if (this.selectedFaceDetector === SSD_MOBILENETV1) {
                  return faceapi.nets.ssdMobilenetv1
              }
              if (this.selectedFaceDetector === TINY_FACE_DETECTOR) {
                  return faceapi.nets.tinyFaceDetector
              }
          },

          isFaceDetectionModelLoaded() {
              return !!this.getCurrentFaceDetectionNet().params
          },
          async onPlay() {
              if (!this.isFaceDetectionModelLoaded()) {
                  setTimeout(this.onPlay, 500);
              }
              var videoEl = this.$refs.inputVideo;

              var faceoptions = new faceapi.TinyFaceDetectorOptions({ inputSize:128,
                                                                      scoreThreshold:0.5 });
              var canvas = this.$refs.overlay;

              var detection = await faceapi.detectSingleFace(videoEl, faceoptions);

              const dims = faceapi.matchDimensions(canvas, videoEl, true)

              if (detection) {
                  faceapi.draw.drawDetections(canvas, faceapi.resizeResults(detection, dims));
                  // the face box is perhaps around 260 x 310
                  // and usually a bit low
                  // we want it to be faceHeight x faceWidth
                  
                  this.faceBox = detection.box;
                  var xmid = this.faceBox.x + this.faceBox.width / 2;
                  var ymid = this.faceBox.y + this.faceBox.height / 2.5;
                  this.faceBox = new faceapi.Rect(xmid - faceWidth/2, ymid - faceHeight / 2, faceWidth, faceHeight);
                  
              }

              const cropface = this.$refs.cropface;
              var facectx = cropface.getContext('2d');

              facectx.drawImage(videoEl,
                                this.faceBox.x, this.faceBox.y,
                                this.faceBox.width, this.faceBox.height,
                                0,0,
                                faceWidth, 320);

              setTimeout(this.onPlay);
          },
          
      },
  }
  
//  videoEl.srcObject = stream


</script>


<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

#overlay, .overlay {
  position: absolute;
  top: 0;
  left: 0;
}

div.inputVideo {
    display: block;
    width: 10%;
    height: 10%;    
}
</style>


