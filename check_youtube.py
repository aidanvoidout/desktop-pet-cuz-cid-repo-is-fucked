import os
import psutil

def is_youtube_open():
    # Iterate through all processes
    for process in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            # Check if process is a browser (Chrome, Firefox, etc.)
            if 'chrome.exe' in process.info['name'].lower() or 'firefox.exe' in process.info['name'].lower():
                # Check if any command line argument contains 'youtube'
                if process.info['cmdline']:
                    if any("youtube.com" in cmd for cmd in process.info['cmdline']):
                        return True
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            # Ignore processes we can't access or have already terminated
            pass
    return False

if __name__ == "__main__":
    if is_youtube_open():
        print("youtube.com is open in a browser!")
    else:
        print("youtube.com is not open in any browser.")
