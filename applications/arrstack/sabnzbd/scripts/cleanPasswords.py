#!/usr/bin/env python3
import sys
import os

def main():
    raw_password = os.environ.get('SAB_PASSWORD', '')
    job_name = os.environ.get('SAB_FILENAME', 'Job')

    if ".onion" in raw_password:
        clean_password = raw_password.split(".onion")[0]
    else:
        clean_password = raw_password

    base_name = job_name.replace(".nzb", "").replace(".NZB", "")
    new_job_string = f"{base_name} / {clean_password}"
    
    print("1")
    print(new_job_string)
    print("")
    print("")
    print("")
    print("")
    print("")
    sys.exit(0)

if __name__ == "__main__":
    main()