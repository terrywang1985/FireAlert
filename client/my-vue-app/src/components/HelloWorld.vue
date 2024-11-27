<template>
  <div id="app">
    <h1>欢迎来到 Vue 3 应用!</h1>
    <button @click="changeMessage">点击我</button>
    <button @click="createRoom">Create Room</button>
    <p>{{ message }}</p>
  </div>
</template>

<script>

import { client, CreateRoomRequest } from '../grpc/client';

export default {
  name: "App",
  data() {
    return {
      message: "Vue 3 是强大的!",
      roomName: "Vue 3 Room"
    };
  },
  methods: {
    changeMessage() {
      this.message = "你点击了按钮!";
    },
    createRoom() {
      console.log("Create Room");
      const request = new CreateRoomRequest();
      request.setRoomName(this.roomName);

      client.createRoom(request, {}, (err, response) => {
        if (err) {
          console.error(err);
        } else {
          console.log('Room created with ID:', response.getRoomId());
        }
      });
    }

  }
};
</script>

<style>
#app {
  text-align: center;
}
button {
  margin: 20px;
  padding: 10px;
  background-color: #42b983;
  color: white;
  border: none;
  cursor: pointer;
}
button:hover {
  background-color: #367a52;
}
</style>
