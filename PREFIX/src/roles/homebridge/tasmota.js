module.exports = {
  init: ({ log, config, publish, notify }) => {
    return {
      encode: (msg) => msg,
      decode: (msg) => msg,
      properties: {
        on: {
          encode: (msg) => (msg ? "ON" : "OFF"),
          decode: (msg) => ({ ON: true, OFF: false }[JSON.parse(msg).POWER]),
        },
        RGBWW: {
          encode: (msg) => {
            const [r, g, b, ww, cw] = msg.split(",").map((x) => Number(x));
            return [r, g, b, cw, ww]
              .map((x) => x.toString(16).padStart(2, "0"))
              .join("");
          },
          decode: (msg) => {
            const data = JSON.parse(msg);
            if ("Color" in data) {
              const [r, g, b, cw, ww] = data.Color.includes(",")
                ? data.Color.split(",").map((x) => Number(x))
                : data.Color.match(/[0-9a-z]{2}/gi).map((x) =>
                    parseInt(x, 16)
                  );
              return [r, g, b, ww, cw].join(",");
            }
          },
        },
      },
    };
  },
};
