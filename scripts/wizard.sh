#!/bin/bash

# AI Voice Offline - Interactive Setup Wizard
# Guida l'utente attraverso setup, build, e run del progetto

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Emoji
CHECK="✅"
CROSS="❌"
ROCKET="🚀"
WRENCH="🔧"
STOP="🛑"
TEST="🧪"
INFO="💡"
WARNING="⚠️"
NEW="🆕"
PLAY="▶️"
BACK="⬅️"
PACKAGE="📦"
WEB="🌐"
GEAR="⚙️"

# Utility functions
print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

print_info() {
    echo -e "${BLUE}${INFO} $1${NC}"
}

print_section() {
    echo -e "\n${BOLD}$1${NC}"
}

wait_for_enter() {
    echo -e "\n${CYAN}Press Enter to continue...${NC}"
    read
}

# Check if GPU is available
check_gpu() {
    if command -v nvidia-smi &> /dev/null; then
        VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
        if [ ! -z "$VRAM" ]; then
            VRAM_GB=$((VRAM / 1024))
            return 0
        fi
    fi
    return 1
}

# Main Menu
show_main_menu() {
    print_header "${ROCKET} AI Voice Conversation - Setup Wizard"

    print_info "Interactive voice conversations with AI"
    echo "  • Speak to AI naturally in 16+ languages"
    echo "  • AI responds in your cloned voice"
    echo "  • Powered by Whisper, Ollama, and XTTS"
    echo ""

    # Detect GPU
    if check_gpu; then
        print_success "Detected: NVIDIA GPU (${VRAM_GB}GB VRAM)"
        print_info "Recommendation: Use GPU Mode for best performance"
        echo ""
    fi

    echo "Choose an option:"
    echo ""
    echo -e "${BOLD}1)${NC} ${NEW}  First Time Setup (New User)"
    echo -e "${BOLD}2)${NC} ${PLAY}  Start Services"
    echo -e "${BOLD}3)${NC} ${STOP}  Stop Services"
    echo -e "${BOLD}4)${NC} ${TEST}  Test Services"
    echo -e "${BOLD}5)${NC} ${WRENCH}  Advanced Options"
    echo -e "${BOLD}6)${NC} ${WEB}  Show Web Interface"
    echo -e "${BOLD}7)${NC} ${CROSS}  Exit"
    echo ""
    echo -n "Your choice [1-7]: "
    read choice

    case $choice in
        1) first_time_setup_menu ;;
        2) start_services_menu ;;
        3) stop_services_menu ;;
        4) test_services_menu ;;
        5) advanced_menu ;;
        6) show_web_interfaces; wait_for_enter; show_main_menu ;;
        7) exit 0 ;;
        *)
            print_error "Invalid choice"
            sleep 1
            show_main_menu
            ;;
    esac
}

# First Time Setup Menu
first_time_setup_menu() {
    print_header "${NEW} First Time Setup - AI Voice Conversation"

    print_info "This will set up the complete voice conversation system:"
    echo "  • Speech-to-Text (Whisper)"
    echo "  • Large Language Model (Ollama)"
    echo "  • Text-to-Speech with Voice Cloning (XTTS)"
    echo ""

    if check_gpu; then
        print_info "GPU Detected: ${VRAM_GB}GB VRAM"
        if [ $VRAM_GB -ge 8 ]; then
            print_success "Your GPU is suitable for GPU mode (recommended)"
            print_info "GPU mode is 10-30x faster than CPU mode"
        else
            print_warning "Limited GPU memory - CPU mode recommended"
        fi
        echo ""
    else
        print_info "No GPU detected - CPU mode will be used"
        print_warning "CPU mode is slower but works on any system"
        echo ""
    fi

    echo "Which mode do you want to use?"
    echo ""
    echo -e "${BOLD}1)${NC} 🚀 GPU Mode (recommended if you have 8GB+ VRAM)"
    echo -e "${BOLD}2)${NC} 💻 CPU Mode (works everywhere, slower)"
    echo -e "${BOLD}3)${NC} ${BACK}  Back to Main Menu"
    echo ""
    echo -n "Your choice [1-3]: "
    read choice

    case $choice in
        1) run_setup gpu ;;
        2) run_setup cpu ;;
        3) show_main_menu ;;
        *)
            print_error "Invalid choice"
            sleep 1
            first_time_setup_menu
            ;;
    esac
}

# Run Setup
run_setup() {
    mode=$1
    print_header "${ROCKET} Running Setup: $mode Mode"

    case $mode in
        cpu)
            print_info "Setting up conversation system in CPU mode..."
            print_info "This will download ~8GB of AI models (TTS, STT, LLM)"
            make setup
            ;;
        gpu)
            if ! check_gpu; then
                print_error "No GPU detected! Cannot use GPU mode."
                print_info "Falling back to CPU mode..."
                sleep 2
                make setup
            else
                print_info "Setting up conversation system in GPU mode..."
                print_info "This will download ~8GB of AI models (TTS, STT, LLM)"
                make setup-gpu
            fi
            ;;
    esac

    if [ $? -eq 0 ]; then
        print_success "Setup completed successfully!"
        echo ""
        print_info "Next steps:"
        echo "  1. Run 'make pull-ollama-model' to download an LLM"
        echo "  2. Run 'make setup-voice' to configure voice cloning (optional)"
        echo ""
        show_web_interfaces
    else
        print_error "Setup failed. Check the errors above."
    fi

    wait_for_enter
    show_main_menu
}

# Start Services Menu
start_services_menu() {
    print_header "${PLAY} Start Services"

    echo "Choose your mode:"
    echo ""
    echo -e "${BOLD}1)${NC} 🚀 Start in GPU Mode (faster, requires NVIDIA GPU)"
    echo -e "${BOLD}2)${NC} 💻 Start in CPU Mode (works everywhere, slower)"
    echo -e "${BOLD}3)${NC} ${BACK}  Back"
    echo ""
    echo -n "Your choice [1-3]: "
    read choice

    case $choice in
        1)
            if ! check_gpu; then
                print_error "No GPU detected!"
                print_info "Please use CPU mode instead"
                sleep 2
                start_services_menu
            else
                print_info "Starting conversation services (GPU mode)..."
                make up-gpu
                print_success "Services started!"
                show_web_interfaces
            fi
            ;;
        2)
            print_info "Starting conversation services (CPU mode)..."
            make up
            print_success "Services started!"
            show_web_interfaces
            ;;
        3) show_main_menu ;;
        *)
            print_error "Invalid choice"
            sleep 1
            start_services_menu
            ;;
    esac

    wait_for_enter
    show_main_menu
}

# Stop Services Menu
stop_services_menu() {
    print_header "${STOP} Stop Services"
    
    echo "What do you want to do?"
    echo ""
    echo -e "${BOLD}1)${NC} ⏸️  Stop All Services (keep containers)"
    echo -e "${BOLD}2)${NC} 🧹 Stop & Clean Containers"
    echo -e "${BOLD}3)${NC} 🗑️  Stop & Remove Everything (including models)"
    echo -e "${BOLD}4)${NC} ${BACK}  Back"
    echo ""
    echo -n "Your choice [1-4]: "
    read choice
    
    case $choice in
        1)
            print_info "Stopping all services..."
            make down
            print_success "Services stopped!"
            ;;
        2)
            print_info "Stopping and cleaning containers..."
            make clean
            print_success "Cleanup complete!"
            ;;
        3)
            print_warning "This will remove EVERYTHING including downloaded models!"
            echo -n "Are you sure? (yes/no): "
            read confirm
            if [ "$confirm" = "yes" ]; then
                make clean-all
                print_success "Complete cleanup done!"
            else
                print_info "Cancelled"
            fi
            ;;
        4) show_main_menu ;;
        *)
            print_error "Invalid choice"
            sleep 1
            stop_services_menu
            ;;
    esac
    
    wait_for_enter
    show_main_menu
}

# Test Services Menu
test_services_menu() {
    print_header "${TEST} Test Services"

    echo "What do you want to test?"
    echo ""
    echo -e "${BOLD}1)${NC} 📊 Check All Services Status (recommended)"
    echo -e "${BOLD}2)${NC} 💬 Test Conversation Service"
    echo -e "${BOLD}3)${NC} 🤖 Test Ollama (LLM)"
    echo -e "${BOLD}4)${NC} ${BACK}  Back"
    echo ""
    echo -n "Your choice [1-4]: "
    read choice

    case $choice in
        1) make check-services ;;
        2) make test-conversation ;;
        3) make test-ollama ;;
        4) show_main_menu ;;
        *)
            print_error "Invalid choice"
            sleep 1
            test_services_menu
            ;;
    esac

    wait_for_enter
    show_main_menu
}

# Advanced Menu
advanced_menu() {
    print_header "${WRENCH} Advanced Options"
    
    echo "Choose an option:"
    echo ""
    echo -e "${BOLD}1)${NC} 📥 Download Ollama Models"
    echo -e "${BOLD}2)${NC} 🎙️  Setup Voice Profile"
    echo -e "${BOLD}3)${NC} 📋 View Logs"
    echo -e "${BOLD}4)${NC} 🔍 Debug Audio Devices"
    echo -e "${BOLD}5)${NC} 📊 Container Status"
    echo -e "${BOLD}6)${NC} 🔄 Restart Services"
    echo -e "${BOLD}7)${NC} ${BACK}  Back"
    echo ""
    echo -n "Your choice [1-7]: "
    read choice
    
    case $choice in
        1) ollama_models_menu ;;
        2) voice_profile_menu ;;
        3) logs_menu ;;
        4) make debug-audio ;;
        5) make status ;;
        6) make restart && print_success "Services restarted!" ;;
        7) show_main_menu ;;
        *)
            print_error "Invalid choice"
            sleep 1
            advanced_menu
            ;;
    esac
    
    wait_for_enter
    show_main_menu
}

# Ollama Models Menu
ollama_models_menu() {
    print_header "📥 Download Ollama Models"
    
    if check_gpu && [ $VRAM_GB -ge 12 ]; then
        print_success "Detected: ${VRAM_GB}GB VRAM"
        print_info "Recommended: Qwen 2.5 7B (excellent multilingual support)"
    elif check_gpu && [ $VRAM_GB -ge 8 ]; then
        print_success "Detected: ${VRAM_GB}GB VRAM"
        print_info "Recommended: Llama 3.2 3B or Qwen 2.5 3B"
    else
        print_info "CPU mode detected"
        print_info "Recommended: TinyLlama 1.1B or Llama 3.2 1B"
    fi
    
    echo ""
    echo "Choose a model to download:"
    echo ""
    echo -e "${BOLD}1)${NC} TinyLlama 1.1B (~637MB, basic, CPU friendly)"
    echo -e "${BOLD}2)${NC} Llama 3.2 1B (~1GB, better quality)"
    echo -e "${BOLD}3)${NC} Llama 3.2 3B (~2GB, good quality, 8GB+ VRAM)"
    echo -e "${BOLD}4)${NC} Qwen 2.5 7B (~4.7GB, excellent multilingual, 12GB+ VRAM)"
    echo -e "${BOLD}5)${NC} List installed models"
    echo -e "${BOLD}6)${NC} ${BACK}  Back"
    echo ""
    echo -n "Your choice [1-6]: "
    read choice
    
    case $choice in
        1) docker exec ollama ollama pull tinyllama:1.1b ;;
        2) docker exec ollama ollama pull llama3.2:1b ;;
        3) docker exec ollama ollama pull llama3.2:3b ;;
        4) docker exec ollama ollama pull qwen2.5:7b ;;
        5) docker exec ollama ollama list ;;
        6) advanced_menu; return ;;
        *)
            print_error "Invalid choice"
            sleep 1
            ollama_models_menu
            return
            ;;
    esac
    
    if [ $? -eq 0 ] && [ $choice -le 4 ]; then
        print_success "Model downloaded successfully!"
        print_warning "Don't forget to update OLLAMA_MODEL in .env and restart services"
    fi
    
    wait_for_enter
    advanced_menu
}

# Voice Profile Menu
voice_profile_menu() {
    print_header "🎙️ Setup Voice Profile"
    
    echo "Choose a method:"
    echo ""
    echo -e "${BOLD}1)${NC} 🎤 Record voice samples (requires microphone)"
    echo -e "${BOLD}2)${NC} 📁 Upload pre-recorded samples"
    echo -e "${BOLD}3)${NC} ${BACK}  Back"
    echo ""
    echo -n "Your choice [1-3]: "
    read choice
    
    case $choice in
        1) make setup-voice ;;
        2) make setup-voice-upload ;;
        3) advanced_menu; return ;;
        *)
            print_error "Invalid choice"
            sleep 1
            voice_profile_menu
            return
            ;;
    esac
    
    wait_for_enter
    advanced_menu
}

# Logs Menu
logs_menu() {
    print_header "📋 View Logs"

    echo "Which logs do you want to view?"
    echo ""
    echo -e "${BOLD}1)${NC} 📋 All Services"
    echo -e "${BOLD}2)${NC} 💬 Conversation Service"
    echo -e "${BOLD}3)${NC} 🤖 Ollama (LLM)"
    echo -e "${BOLD}4)${NC} 🎤 TTS Service"
    echo -e "${BOLD}5)${NC} 🎧 Whisper (STT)"
    echo -e "${BOLD}6)${NC} ${BACK}  Back"
    echo ""
    echo -n "Your choice [1-6]: "
    read choice

    case $choice in
        1) make logs ;;
        2) make logs-conversation ;;
        3) make logs-ollama ;;
        4) make logs-tts ;;
        5) make logs-whisper ;;
        6) advanced_menu; return ;;
        *)
            print_error "Invalid choice"
            sleep 1
            logs_menu
            return
            ;;
    esac

    wait_for_enter
    advanced_menu
}

# Show Web Interfaces
show_web_interfaces() {
    print_section "${WEB} Web Interface Available:"
    echo ""
    echo -e "  ${GREEN}●${NC} ${BOLD}AI Voice Conversation:${NC} ${CYAN}http://localhost:8080${NC}"
    echo ""
    print_info "Features:"
    echo "  • Voice-to-voice conversations with AI"
    echo "  • Multilingual support (16+ languages)"
    echo "  • Voice cloning (use your own voice)"
    echo "  • Model selection (switch between LLMs)"
    echo ""
}

# Main execution
main() {
    # Check if we're in the project directory
    if [ ! -f "Makefile" ]; then
        print_error "Error: Makefile not found!"
        print_info "Please run this script from the project root directory"
        exit 1
    fi
    
    # Welcome message
    print_header "${ROCKET} Welcome to AI Voice Conversation Wizard!"
    print_info "This wizard will help you set up and manage your AI voice conversation system"
    echo ""
    print_info "System features:"
    echo "  • Natural voice conversations with AI"
    echo "  • Voice cloning (AI speaks in your voice)"
    echo "  • 16+ languages supported"
    echo "  • Completely offline and private"
    echo ""
    print_info "You can run this wizard anytime with: ${BOLD}make wizard${NC}"
    wait_for_enter
    
    # Show main menu
    show_main_menu
}

# Run main
main
