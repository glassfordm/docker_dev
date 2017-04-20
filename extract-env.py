import os
import sys

def main():
    DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    find_name = sys.argv[1]
    with open(os.path.join(DIR, '.env'), 'r') as f:
        for line in f:
            if line.startswith('#') or not line.strip():
                continue
            name, value = line.split('=')
            if name == find_name:
                print value
                return

if __name__ == "__main__":
    main()
