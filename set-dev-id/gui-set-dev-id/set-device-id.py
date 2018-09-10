#!/usr/bin/env python3
# coding: utf-8
#
# Author Feb 2018 xuzhenxing <xuzhenxing@canaan-creative.com>
#


import serial
import logging
import sys
from tkinter import *
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


def set_id(current_id, set_id):
    '''
    Device addr; func: read:0x03, write:0x10(16);
    MODBUS protocol read/write
    If write func is wrong, return 0xff
    CRCMODBUS protocol write:
    device-id, func, start-reg-hi, start-reg-lo, data-reg-hi, data-reg-lo, bytecount, value-hi, value-lo, crc-lo, crc-hi
    '''

    # Opening the serial port
    COM_PortName = "/dev/ttyUSB0"
    COM_Port = serial.Serial(COM_PortName, timeout=3)  # Open the COM port
    logging.debug('Com Port: %s, %s', COM_PortName, 'Opened')

    COM_Port.baudrate = 2400                # Set Baud rate
    COM_Port.bytesize = 8                   # Number of data bits = 8
    COM_Port.parity   = 'N'                 # No parity
    COM_Port.stopbits = 1                   # Number of Stop bits = 1

    # Init data
    data = [0x00, 0x10, 0x00, 0x15, 0x00, 0x01, 0x02, 0x00, 0x03]

    # Current device id value
    if (set_id >= 1) and (set_id <= 247):
        data[0] = current_id
        print("Please input current device ID: %d" % data[0])
    else:
        logging.info("Current Device ID is invaild.")
        COM_Port.close()
        sys.exit()

    # Setting device id value
    if (set_id >= 1) and (set_id <= 247):
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
    ''' Tools for setting power device id '''

    root = Tk()
    root.title('Tools for setting power device id')
    root.geometry('850x300')

    for i in range(5):
        Label(root, text='').grid(row=i)

    Label(root, text='\t\t\t当前设备ID值: ').grid(row=6, column=1)
    Label(root, text='\t\t\t设置设备ID值: ').grid(row=7, column=1)
    Label(root, text='').grid(row=8)

    current = StringVar()
    setting = StringVar()
    current_value = Entry(root, textvariable=current)
    setting_value = Entry(root, textvariable=setting)
    current_value.grid(row=6, column=2, padx=10, pady=5)
    setting_value.grid(row=7, column=2, padx=30, pady=5)

    def run():
        set_id(current_value.get(), setting_value.get())
        easygui.msgbox('\n\n\n\n\t\t\t\tSetting Success!', title='Tools for setting power device id')

    Button(root, text='Enter', width=10, command=run).grid(row=9, \
            column=3, sticky=W, padx=10, pady=5)
    Button(root, text='Quit', width=10, command=root.quit).grid(row=9, \
            column=4, sticky=E, padx=10, pady=5)

    root.mainloop()


if __name__ == '__main__':
    setup()
