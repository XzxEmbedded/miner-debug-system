#!/usr/bin/env python
# -*- coding:utf-8 -*-
#
# Author Feb 2018 xuzhenxing <xuzhenxing@canaan-creative.com>
#
# RS485 MODBUS Protocol:
# Device addr; func: read:0x03, write:0x10(16);
# MODBUS protocol read/write
# If write func is wrong, return 0xff
# CRCMODBUS protocol write:
# device-id, func, start-reg-hi, start-reg-lo, data-reg-hi, data-reg-lo, bytecount, value-hi, value-lo, crc-lo, crc-hi
#

import serial
import logging
import sys
import easygui

logging.basicConfig(level=logging.INFO)


def rs485_read():
    ''' Read RS485 datas '''

    read_data = []

    try:
        for i in range(8):
            rx_data = COM_Port.read()
            read_data.append(hex(ord(rx_data)))
        logging.info('Read Bytes: %s', read_data)
    except:
        return False

    return True


def rs485_write(data):
    ''' Write RS485 datas '''

    bytes_cnt  = COM_Port.write(data)   # Write data to serial port
    logging.debug('Write Count = %d. %s ', bytes_cnt, 'bytes written')


# CRC16-MODBUS
def crc16_byte(data):
    crc = data

    for i in range(8):
        if (crc & 0x01):
            crc = (crc >> 1) ^ 0xa001
        else:
            crc >>= 1

    return crc


def crc16_bytes(data):
    crc = 0xffff

    for byte in data:
        crc = crc16_byte(crc ^ byte)

    return crc


def set_id(usb_port, current_id, set_id):
    ''' Setting Device id '''

    global COM_Port

    # Opening the serial port
    COM_PortName = usb_port
    COM_Port = serial.Serial(COM_PortName, timeout=3)  # Open the COM port
    logging.debug('Com Port: %s, %s', COM_PortName, 'Opened')

    COM_Port.baudrate = 2400                # Set Baud rate
    COM_Port.bytesize = 8                   # Number of data bits = 8
    COM_Port.parity   = 'N'                 # No parity
    COM_Port.stopbits = 1                   # Number of Stop bits = 1

    # Init data
    data = [0x00, 0x10, 0x00, 0x15, 0x00, 0x01, 0x02, 0x00, 0x03]

    # Current device id value
    current_id = int(current_id)
    if (current_id >= 1) and (current_id <= 256):
        data[0] = current_id
        print("Please input current device ID: %d" % data[0])
    else:
        logging.info("Current Device ID is invaild.")
        COM_Port.close()
        sys.exit()

    # Setting device id value
    set_id = int(set_id)
    if (set_id >= 1) and (set_id <= 256):
        data[7] = set_id
        print("Please input setting device ID: %d" % data[7])
    else:
        logging.info("Setting Device ID is invaild.")
        COM_Port.close()
        sys.exit()

    crc = crc16_bytes(data)
    low = int(crc & 0xff)
    high = int((crc >> 8) & 0xff)
    data.append(low)
    data.append(high)
    logging.debug('%s', data)

    rs485_write(data)
    if not rs485_read():
        print("Setting device id failed.")
        COM_Port.close()
        sys.exit()

    logging.info("Setting Device ID success, new device ID is %d", data[7])
    COM_Port.close()


def setup():

    title = "设置功率器设备ID工具"
    names = ['串口: ', '当前设备ID值: ', '设置设备ID值: ']
    fields = []

    while True:
        fields = easygui.multenterbox('', title, names, fields)
        if (fields[0] == '') or (fields[1] == '') or (fields[2] == ''):
            continue
        break

    set_id(fields[0], fields[1], fields[2])

if __name__ == '__main__':
    setup()
