# encoding: UTF-8
#
# = exe_appender.rb - Windows PE Appender
#
# Author:: Brandon Wamboldt <brandon.wamboldt@gmail.com>
# Copyright:: Copyright (c) 2016 Brandon Wamboldt
# License:: MIT and/or Creative Commons Attribution-ShareAlike

# Class used to append data to the end of a Windows Portable Executable (PE)
# without invalidating the Windows Digital Signature. Byte offset of the payload
# is added to the end of the file as an unsigned int.
#
# The way Microsoft authenticode works is the following. During the signature
# process, it computes the hash on the executable file. The hash is then used to
# make a digital certificate which is authenticated by some authority. This
# certificate is attached to the end of the PE exectuable, in a dedicated
# section called the Certificate Table. When the executable is loaded, Windows
# computes the hash value, and compares it to the one attached to the
# Certificate table. It is “normally” impossible to change anything in the file
# without breaking the digital authentication.
#
# However three areas of a PE executable are excluded from the hash computation:
#
#  - The checksum in the optional Windows specific header. 4 bytes
#  - The certificate table entry in the optional Windows specific header. 8 bytes
#  - The Digital Certificate section at the end of the file. Variable length
#
# You should be able to change those area without breaking the signature. It is
# possible to append an arbitrary amount of data at the end of the Digital
# Certificate. This data is ignored by both the signature parsing and hash
# computation algorithms. It works on all version of Window as long as the
# length of the Certificate Table is correctly increased. The length is stored
# in two different location: the PE header and the beginning of the certificate
# table.
#
# - https://blog.barthe.ph/2009/02/22/change-signed-executable/
# - https://github.com/rolftimmermans/node-exe-append
class ExeAppender
  # Portable Executable file format magic constants
  PE_OFFSET_OFFSET = 0x3c
  PE_HEADER = 0x00004550

  # Unix Common Object File Format magic constants
  COFF_OPT_LENGTH_OFFSET = 20
  COFF_OPT_OFFSET = 24
  COFF_MAGIC = 0x10b
  COFF_CHECKSUM_OFFSET = 64

  # PE Certificate Table magic constants
  CERT_OFFSET_OFFSET = 128
  CERT_LENGTH_OFFSET = 132

  def initialize(filename)
    @filename = filename
    @file = File.binread(@filename)
  end

  # Append data to the EXE, updating checksums and digital certificate tables if
  # needed.
  def append(data)
    data     += [@file.bytesize].pack('V')
    pe_offset = read_uint32(@file, PE_OFFSET_OFFSET)

    unless read_uint32(@file, pe_offset) == PE_HEADER
      raise StandardError.new("No valid PE header found")
    end

    if read_uint16(@file, pe_offset + COFF_OPT_LENGTH_OFFSET) == 0
      raise StandardError.new("No optional COFF header found")
    end

    unless read_uint16(@file, pe_offset + COFF_OPT_OFFSET) == COFF_MAGIC
      raise StandardError.new("PE format is not PE32")
    end

    cert_offset = read_uint16(@file, pe_offset + COFF_OPT_OFFSET + CERT_OFFSET_OFFSET)

    if cert_offset > 0
      # Certificate table found, modify certificate lengths
      cert_length = read_uint32(@file, pe_offset + COFF_OPT_OFFSET + CERT_LENGTH_OFFSET)

      unless read_uint32(@file, cert_offset) != cert_length
        raise StandardError.new("Certificate length does not match COFF header")
      end

      new_length = cert_length + data.length
      write_uint_32(@file, new_length, pe_offset + COFF_OPT_OFFSET + CERT_LENGTH_OFFSET)
      write_uint_32(@file, new_length, cert_offset)
    end

    # Calculate and update checksum of end result
    @file += data
    offset = pe_offset + COFF_OPT_OFFSET + COFF_CHECKSUM_OFFSET
    write_uint_32(@file, checksum, offset)
  end

  # Write the modified EXE to a file
  def write(filename=nil)
    filename = @filename unless filename
    File.binwrite(filename, @file)
  end

  private

  # http://stackoverflow.com/questions/6429779/can-anyone-define-the-windows-pe-checksum-algorithm
  def checksum
    limit = 2**32
    checksum = 0

    (0..@file.bytesize).step(4).each do |i|
      next if (i + 4) > @file.bytesize
      val       = read_uint32(@file, i)
      checksum += val
      checksum  = (checksum % limit) + (checksum / limit | 0) if checksum >= limit
    end

    if @file.bytesize % 4 > 0
      trailer = @file[(@file.bytesize - (@file.bytesize % 4))..@file.bytesize]

      (1..(4 - @file.bytesize % 4)).each do
        trailer << 0
      end

      val       = read_uint32(trailer, 0)
      checksum += val
      checksum  = (checksum % limit) + (checksum / limit | 0) if checksum >= limit
    end

    checksum = unsigned_right_shift(checksum, 16) + (checksum & 0xffff)
    checksum = unsigned_right_shift(checksum, 16) + checksum

    (checksum & 0xffff) + @file.bytesize
  end

  def unsigned_right_shift(val, shift_by)
    mask = (1 << (32 - shift_by)) - 1
    (val >> shift_by) & mask
  end

  # Read 8 bit unsigned little endian integer
  def read_uint8(str, offset)
    str[offset..(offset + 2)].unpack('C')[0]
  end

  # Read 16 bit unsigned little endian integer
  def read_uint16(str, offset)
    str[offset..(offset + 2)].unpack('v')[0]
  end

  # Read 32 bit unsigned little endian integer
  def read_uint32(str, offset)
    str[offset..(offset + 4)].unpack('V')[0]
  end

  # Write 32 bit unsigned little endian integer
  def write_uint_32(str, int, offset)
    str[offset..(offset + 3)] = [int].pack('V')
  end
end

