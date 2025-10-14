# python_check_fsm.py
fsm_rules = {
    '00': {'0': '00', '1': '10'},  # S0
    '01': {'0': '11', '1': '00'},  # S1
    '10': {'0': '10', '1': '01'},  # S2
    '11': {'0': '10', '1': '11'}   # S3
}

log_file = "C:\\Users\\jiang\\OneDrive\\LabFile\\Lab4\\Prac\\fsm_log.txt"  # 你的 XSim console log 檔名

prev_state = None
prev_led0 = None
errors = 0

with open(log_file, "r") as f:
    for line in f:
        if "After next pressed" not in line:
            continue

        try:
            # 取 state 與 LED[0]
            info = line.split("|")[2].strip()  # "state=10, LED=111000001, LED[0]=1"
            kvs = [kv.strip() for kv in info.split(",")]  # ['state=10', 'LED=111000001', 'LED[0]=1']
            state_str = kvs[0].split("=")[1]
            led0 = kvs[2].split("=")[1]
        except Exception as e:
            print(f"Warning: could not parse line: {line.strip()}")
            continue

        if prev_state is not None and prev_led0 is not None:
            expected_state = fsm_rules[prev_state][prev_led0]
            if state_str != expected_state:
                print(f"ERROR at {line.strip()}: expected {expected_state}, got {state_str}")
                errors += 1
            else:
                print(f"OK at {line.strip()}: prev_state={prev_state}, LED[0]={prev_led0} -> {state_str}")

        prev_state = state_str
        prev_led0 = led0

print(f"Total errors: {errors}")
