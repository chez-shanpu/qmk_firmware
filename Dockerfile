FROM qmkfm/base_container

VOLUME /qmk_firmware
WORKDIR /qmk_firmware
COPY . .

ENV KEYBOARD all
ENV KEYMAP default

CMD make ${KEYBOARD}:${KEYMAP}
