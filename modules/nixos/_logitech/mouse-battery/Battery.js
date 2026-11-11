function parseBattery(output, exitCode) {
    if (exitCode !== 0)
        return null;
    const match = output.match(/^\s*Battery:\s*(\d+)%/m);
    if (!match)
        return null;
    const percentage = Number(match[1]);
    return percentage <= 100 ? percentage : null;
}
