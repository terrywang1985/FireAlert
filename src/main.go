package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"net"
	"sync"

	pb "FireAlert/src/generated/chat"
	"google.golang.org/grpc"
)

type server struct {
	pb.UnimplementedChatServiceServer
	rooms map[string][]chan pb.ChatMessage
	mu    sync.Mutex
}

func (s *server) CreateRoom(ctx context.Context, req *pb.CreateRoomRequest) (*pb.CreateRoomResponse, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	log.Println("Creating room, req: ", req.String())
	roomID := fmt.Sprintf("%d", len(s.rooms)+1)
	s.rooms[roomID] = []chan pb.ChatMessage{}
	return &pb.CreateRoomResponse{RoomId: roomID}, nil
}

func (s *server) JoinRoom(ctx context.Context, req *pb.JoinRoomRequest) (*pb.JoinRoomResponse, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	log.Println("Join room, req: ", req.String())

	if _, ok := s.rooms[req.RoomId]; !ok {
		return &pb.JoinRoomResponse{Success: false}, nil
	}
	return &pb.JoinRoomResponse{Success: true}, nil
}

func (s *server) SendMessage(stream pb.ChatService_SendMessageServer) error {
	log.Println("Client now connected as a long running stream")
	defer log.Println("Client disconnected")

	// Create a channel for this client
	msgChan := make(chan pb.ChatMessage)
	defer close(msgChan)

	// Add this client's channel to the room
	s.mu.Lock()
	roomID := ""
	for {
		msg, err := stream.Recv()
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}
		roomID = msg.RoomId
		log.Println("append a new client to room: ", roomID)
		s.rooms[roomID] = append(s.rooms[roomID], msgChan)
		break
	}
	s.mu.Unlock()

	// Start a goroutine to send messages to the client
	go func() {
		for msg := range msgChan {
			log.Printf("Send message to room, info: %s ", msg.String())
			if err := stream.Send(&msg); err != nil {
				log.Printf("Failed to send message to client: %v", err)
				return
			}
		}
	}()

	// Receive messages from the client and broadcast them to the room
	for {
		msg, err := stream.Recv()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		s.mu.Lock()
		fmt.Printf("Received message: %s ", msg.String())
		for _, ch := range s.rooms[msg.RoomId] {
			ch <- *msg
		}
		s.mu.Unlock()
	}

	// Remove this client's channel from the room
	s.mu.Lock()
	channels := s.rooms[roomID]
	for i, ch := range channels {
		if ch == msgChan {
			s.rooms[roomID] = append(channels[:i], channels[i+1:]...)
			break
		}
	}
	s.mu.Unlock()

	return nil
}

func main() {
	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	} else {
		log.Println("Server started")
	}
	s := grpc.NewServer()
	pb.RegisterChatServiceServer(s, &server{rooms: make(map[string][]chan pb.ChatMessage)})
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
