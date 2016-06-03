// Dezyne --- Dezyne command line tools
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Dezyne.
//
// Dezyne is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Dezyne is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#ifndef USB_HH
#define USB_HH

#include <usb.h>

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <stdexcept>
#include <string>
#include <vector>

namespace lego
{
  const int USB_ID_VENDOR_LEGO = 0x0694;
  const int USB_ID_PRODUCT_NXT = 0x0002;
  const int USB_OUT_ENDPOINT = 0x01;
  const int USB_IN_ENDPOINT = 0x82;
  const int USB_TIMEOUT = 1000;

  inline std::uint16_t lsw(std::uint32_t w)
  {
    return std::uint16_t(0xffff & w);
  }
  inline std::uint16_t msw(std::uint32_t w)
  {
    return std::uint16_t(0xffff & (w >> 16));
  }
  inline std::uint8_t lsb(std::uint16_t w)
  {
    return std::uint8_t(0xff & w);
  }
  inline std::uint8_t msb(std::uint16_t w)
  {
    return std::uint8_t(0xff & (w >> 8));
  }

  struct USB
  {
    typedef struct usb_device usb_device;

    struct Device
    {
      usb_device* device;
      usb_dev_handle* handle;
      Device(usb_device* device)
      : device(device)
      , handle(usb_open(device))
      {
        usb_reset(handle);
        if (device->config and device->config->interface and device->config->interface->altsetting)
        {
          usb_claim_interface(handle, device->config->interface->altsetting->bInterfaceNumber);
        }
        else
        {
          throw std::runtime_error("cannot claim interface");
        }
      }
      Device(Device&& that)
      : device(that.device)
      , handle(that.handle)
      {
        that.device = nullptr;
        that.handle = nullptr;
      }
      Device(const Device&) = delete;
      ~Device()
      {
        if(device) usb_release_interface(handle, device->config->interface->altsetting->bInterfaceNumber);
        if(handle) usb_close(handle);
      }
      void set_name(std::string name)
      {
        name.resize(std::max(std::string::size_type(14), name.size()));
        std::array<std::uint8_t,17> request{0x01, 0x98};
        std::copy(name.begin(), name.end(), reinterpret_cast<char*>(request.data()+2));
        write(request);

        std::array<std::uint8_t,3> response{0};
        read(response);
      }

      std::string get_name()
      {
        std::array<std::uint8_t,2> request{0x01, 0x9b};
        write(request);

        std::array<std::uint8_t,33> response{0};
        read(response);

        std::string name(reinterpret_cast<char*>(response.data()+3));
        return name;
      }
      std::tuple<std::uint16_t,std::uint16_t,std::uint16_t,std::uint16_t> get_version()
      {
        std::array<std::uint8_t,2> request{0x01, 0x88};
        write(request);

        std::array<std::uint8_t,7> response{0};
        read(response);

        return std::make_tuple<std::uint16_t,std::uint16_t,std::uint16_t,std::uint16_t>(response[4], response[3], response[6], response[5]);
      }
      void move(std::uint8_t port, std::int8_t power, bool regulated, std::uint32_t inc)
      {
        std::uint8_t mode = 0x01;
        if(regulated) mode |= 0x02 | 0x04;

        std::array<std::uint8_t,12> request{ 0x80, 0x04, port, reinterpret_cast<std::uint8_t&>(power), mode, 0x01, 0, 0x20, 0, 0, 0, 0};
        reinterpret_cast<std::uint32_t&>(request[8]) = inc;
        write(request);
      }

      void stop(std::uint8_t port)
      {
        std::array<std::uint8_t,12> request{ 0x80, 0x04, port, 0, 0x01 | 0x02, 0x01, 0, 0x20, 0, 0, 0, 0 };
        write(request);
      }

      void coast(std::uint8_t port)
      {
        std::array<std::uint8_t,12> request{ 0x80, 0x04, port, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
        write(request);
      }

      bool at(std::uint8_t port, std::int32_t desired)
      {
        std::int32_t current = get_position(port);
        return std::abs(desired - current) <= 2;
      }

      std::int32_t get_position(std::uint8_t port)
      {
        std::array<std::uint8_t,3> request{ 0x0, 0x06, port};
        write(request);
        std::array<std::uint8_t,25> response{0};
        read(response);
        return reinterpret_cast<std::int32_t&>(response[21]);
      }

      void zero(std::uint8_t port)
      {
        std::array<std::uint8_t,4> request{ 0x80, 0x0A, port, 0x00};
        write(request);
      }

      void play_note(std::uint16_t freq, std::uint16_t length)
      {
        std::array<std::uint8_t,6> request{ 0x80, 0x03, lsb(freq), msb(freq), lsb(length), msb(length)};
        write(request);
      }
      void set_input_mode(std::uint8_t port, std::uint8_t type, std::uint8_t mode)
      {
        std::array<std::uint8_t,5> request{ 0x80, 0x05, port, type, mode};
        write(request);
      }
      std::int16_t get_input_values(std::uint8_t port)
      {
        std::array<std::uint8_t,3> request{ 0x00, 0x07, port};
        write(request);

        std::array<std::uint8_t,16> response{0};
        read(response);
        return reinterpret_cast<std::int16_t&>(response[12]);
      }
    private:
      template <typename Message>
      void write(const Message& request)
      {
        usb_bulk_write(handle, USB_OUT_ENDPOINT, reinterpret_cast<const char*>(request.data()), request.size(), USB_TIMEOUT);
      }
      template <typename Message>
      void read(Message& request)
      {
        usb_bulk_read(handle, USB_IN_ENDPOINT, reinterpret_cast<char*>(request.data()), request.size(), USB_TIMEOUT);
      }
    };

    std::vector<Device> devices;
    USB()
    {
      usb_init();
      usb_find_busses();
      usb_find_devices();

      for (auto bus = usb_get_busses(); bus; bus = bus->next)
      {
        for (usb_device* dev = bus->devices; dev; dev = dev->next)
        {
          if ((dev->descriptor.idVendor == USB_ID_VENDOR_LEGO) and
              (dev->descriptor.idProduct == USB_ID_PRODUCT_NXT))
          {
            this->devices.emplace_back(dev);
          }
        }
      }
    }
    ~USB()
    {
      for(auto& device: devices)
      {
        for(auto i = 0; i <= 2; ++i) device.coast(i);
        for(auto i = 0; i <= 3; ++i) device.set_input_mode(i, 0, 0);
      }
    }
  };
}

#endif
