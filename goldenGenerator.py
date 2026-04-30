import csv
import random

DATA_WIDTH = 8
FILTER_N = 5

params = [3, 64, 122, 64, 3]

directed_samples = [
    10, 20, 30, 40, 50,
    45, 60, 133, 70,
]

random_samples = [random.randint(0, 255) for _ in range(20)]

samples = directed_samples + random_samples

shift_regs = [0] * FILTER_N

with open("fir_vectors.csv", "w", newline="") as csv_file:
    writer = csv.writer(csv_file)

    header = ["data"]
    header += [f"param{i}" for i in range(FILTER_N)]
    header += ["expected"]

    writer.writerow(header)

    for sample in samples:
        shift_regs = [sample] + shift_regs[:-1]

        expected = 0
        for i in range(FILTER_N):
            expected += shift_regs[i] * params[i]

        writer.writerow([sample] + params + [expected])