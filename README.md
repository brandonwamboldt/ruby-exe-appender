Windows PE Appender
===================

This is a Ruby library for appending arbitrary data to a signed Windows executable. The additional payload is appended to the end of the file, in the digital certificate section, and the certificate table and checksums are updated appropriately.

This method is described in detail by the following blog post: http://blog.barthe.ph/2009/02/22/change-signed-executable/

Usage
-----

```ruby
require('exe_appender')

exe = ExeAppender.new('ConsoleApplication1.exe')
exe.append('This is some arbitrary data appended to the end of the PDF. Woo123')
exe.write('ConsoleApplication.exe')
```

There is a C++ example of how to read data from the end of the exe in the examples folder. This library adds a 32 bit unsigned integer to the end of the EXE containing the byte offset where the payload starts. Therefore you simply need to read from the byte offset to the end of the file minus 4 bytes.

License
-------

This library is licensed under the MIT license, and is safe for commercial use.
