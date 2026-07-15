package main
import (
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("error loading .env file")
	}
	gitea_token := os.Getenv("GITEA_TOKEN") 
	forgejo_token := os.Getenv("FORGEJO_TOKEN")
	fmt.Printf("gitea token %s, forgejo token %s", gitea_token, forgejo_token)
}
