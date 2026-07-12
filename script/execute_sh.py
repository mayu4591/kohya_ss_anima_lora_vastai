import time
import subprocess
import portalocker
import os

def read_first_line(file_path):
    with open(file_path, 'a+') as file:
        portalocker.lock(file, portalocker.LOCK_EX)
        try:
            file.seek(0)
            lines = file.readlines()

            while lines and not lines[0].strip():
                lines.pop(0)

            command = None
            if lines:
                command = lines.pop(0).strip()

            file.seek(0)
            file.truncate()
            file.writelines(lines)
            file.flush()
            return command
        finally:
            portalocker.unlock(file)

def append_line(file_path, line):
    line = line.strip()
    if not line:
        return

    with open(file_path, 'a') as file:
        portalocker.lock(file, portalocker.LOCK_EX)
        try:
            file.write(line + '\n')
            file.flush()
        finally:
            portalocker.unlock(file)

def execute_command(command):
    _, ext = os.path.splitext(command)
    try:
        if ext.lower() == '.sh':
            # .shファイルの場合
            return subprocess.call(['/bin/bash', command])

        # .shファイル以外の場合、コマンドをそのまま実行
        return subprocess.call(command.split())
    except OSError as error:
        print(f'Failed to start command: {command}: {error}')
        return -1

def main():
    file_path = '/tmp/q.txt'
    open(file_path, 'a').close()

    try:
        while True:
            try:
                command = read_first_line(file_path)
                if command:
                    result = execute_command(command)
                    if result != 0:
                        print(f'Failed to execute command: {command}')
                        append_line(file_path, command)
                else:
                    time.sleep(1)  # q.txtが空の場合は1秒待つ
            except FileNotFoundError:
                open(file_path, 'a').close()
                time.sleep(1)
            except Exception as error:
                print(f'Unexpected error: {error}')
                time.sleep(1)
    except KeyboardInterrupt:
        print("プログラムが終了しました。")

if __name__ == "__main__":
    main()