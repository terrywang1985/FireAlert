package main

import (
	pb "FireAlert/src/generated/chat"
	"bufio"
	"context"
	"google.golang.org/grpc"
	"log"
	"os"
)

func main() {
	conn, err := grpc.Dial("localhost:50051", grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewChatServiceClient(conn)

	// Create a room
	roomResp, err := c.CreateRoom(context.Background(), &pb.CreateRoomRequest{RoomName: "TestRoom"})
	if err != nil {
		log.Fatalf("could not create room: %v", err)
	}
	roomID := roomResp.RoomId
	log.Printf("Created room with ID: %s", roomID)

	// Join the room
	joinResp, err := c.JoinRoom(context.Background(), &pb.JoinRoomRequest{RoomId: roomID, UserName: "User1"})
	if err != nil || !joinResp.Success {
		log.Fatalf("could not join room: %v", err)
	}
	log.Printf("Joined room with ID: %s", roomID)

	// Start sending and receiving messages
	stream, err := c.SendMessage(context.Background())
	if err != nil {
		log.Fatalf("could not send message: %v", err)
	}

	go func() {
		for {
			msg, err := stream.Recv()
			if err != nil {
				log.Fatalf("could not receive message: %v", err)
			}
			log.Printf("%s: %s", msg.UserName, msg.Message)
		}
	}()

	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		text := scanner.Text()
		if err := stream.Send(&pb.ChatMessage{RoomId: roomID, UserName: "User1", Message: text}); err != nil {
			log.Fatalf("could not send message: %v", err)
		}
	}
	if err := scanner.Err(); err != nil {
		log.Fatalf("error reading from stdin: %v", err)
	}
}
