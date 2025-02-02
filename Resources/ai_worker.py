#!/usr/bin/env python3
import sys
from ollama import chat, ChatResponse

def ollama_chat(prompt_text: str, model: str = "deepseek-r1:1.5b") -> None:
    """
    Uses the Ollama library to chat with the specified model.
    Prints only the generated message content to stdout.
    """
    try:
        # Call the Ollama chat function with a message from the user.
        response: ChatResponse = chat(
            model=model,
            messages=[
                {"role": "user", "content": prompt_text}
            ]
        )
        # Print the generated content.
        # You can use either indexing:
        # print(response['message']['content'])
        # or attribute access:
        print(response.message.content)
    except Exception as e:
        # Write any errors to stderr, so they don't appear in stdout.
        sys.stderr.write(f"Error in ollama_chat: {e}\n")

def main() -> None:
    # Expect at least two arguments: a command and a prompt.
    if len(sys.argv) < 3:
        sys.stderr.write("Usage: ai_worker.py ollama <prompt_text>\n")
        return

    command = sys.argv[1].lower()

    if command == "ollama":
        prompt_text = " ".join(sys.argv[2:])
        ollama_chat(prompt_text)
    else:
        sys.stderr.write("Unknown command. Use: ai_worker.py ollama <prompt_text>\n")

if __name__ == "__main__":
    main()
