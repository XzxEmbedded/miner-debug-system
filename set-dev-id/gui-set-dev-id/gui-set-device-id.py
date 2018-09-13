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
        logging.debug('Read Bytes: %s', read_data)
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
    ''' Setting Device id '''

    # Init data
    data = [0x00, 0x10, 0x00, 0x15, 0x00, 0x01, 0x02, 0x00, 0x03]

    # Current device id value
    current_id = int(current_id)
    if (current_id >= 1) and (current_id <= 256):
        data[0] = current_id
        logging.debug("Current device ID is %d" % data[0])
    else:
        logging.info("Current Device ID is invaild.")
        return False

    # Setting device id value
    set_id = int(set_id)
    if (set_id >= 1) and (set_id <= 256):
        data[7] = set_id
        logging.debug("Setting New Device ID is %d" % data[7])
    else:
        logging.info("Setting Device ID is invaild.")
        return False

    crc = crc16_bytes(data)
    low = int(crc & 0xff)
    high = int((crc >> 8) & 0xff)
    data.append(low)
    data.append(high)
    logging.debug('%s', data)

    rs485_write(data)
    if not rs485_read():
        logging.info("Setting device id failed.")
        return False

    return True


def setup():
    ''' Setup GUI '''

    global COM_Port

    # Check Serial inferface
    port_prefix = 'COM'
    index = 0

    while True:
        try:
            usb_port = port_prefix + str(index)

            # Opening the serial port
            COM_PortName = usb_port
            COM_Port = serial.Serial(COM_PortName, timeout=3)  # Open the COM port
            logging.debug('Com Port: %s, %s', COM_PortName, 'Opened')

            COM_Port.baudrate = 2400                # Set Baud rate
            COM_Port.bytesize = 8                   # Number of data bits = 8
            COM_Port.parity   = 'N'                 # No parity
            COM_Port.stopbits = 1                   # Number of Stop bits = 1

            break
        except:
            index = index + 1
            # Check range for 0 - 100
            if index > 100:
                print("Do not check COM")
                return False
            continue


    title = "设置功率器设备ID工具"
    names = ['串口: ', '当前设备ID值: ', '设置设备ID值: ']
    fields = []
    fields.append(usb_port)

    while True:
        fields = easygui.multenterbox('', title, names, fields)
        if fields == None:
            COM_Port.close()
            return False

        if (set_id(fields[1], fields[2])):
            easygui.msgbox("\n\n\n\n\t\t设置新设备ID成功，为确保无误, 请检测一下功率器是否设置成功。", \
                    title="设置功率器设备ID工具")
        else:
            easygui.msgbox("\n\n\n\n\t\t\t设置新设备ID失败，请重新设置设备ID。", \
                    title="设置功率器设备ID工具")

    COM_Port.close()
    return True

if __name__ == '__main__':
    while True:
        if not setup():
            sys.exit()
