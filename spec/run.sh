
cd ..
babel-node index.js spec/libretro.h > spec/libretro.idl
python2 /Users/matthew/emsdk_portable/emscripten/1.30.0/tools/webidl_binder.py spec/libretro.idl glue
