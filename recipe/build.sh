#!/bin/bash

set -exuo pipefail

rm -r cmake/external/onnx cmake/external/eigen
mv onnx eigen cmake/external/

pushd cmake/external/SafeInt/safeint
ln -s $PREFIX/include/SafeInt.hpp
popd

pushd cmake/external/json
ln -s $PREFIX/include single_include
popd

# Needs eigen 3.4
# rm -rf cmake/external/eigen
# pushd cmake/external
# ln -s $PREFIX/include/eigen3 eigen
# popd

CUDA_ARGS=""
CMAKE_CUDA_EXTRA_DEFINES=""
if [[ $build_type == "cuda" ]]
then
  export CUDNN_HOME=$PREFIX
  CUDA_ARGS=" --use_cuda "
  CMAKE_CUDA_EXTRA_DEFINES="CMAKE_CUDA_COMPILER=${CUDA_HOME}/bin/nvcc CMAKE_CUDA_HOST_COMPILER=${CXX}"
fi

export CUDACXX=$CUDA_HOME/bin/nvcc

if [[ ! -z "${cuda_compiler_version+x}" && "${cuda_compiler_version}" != "None" ]]; then
  BUILD_ARGS="--use_cuda --cuda_home ${CUDA_HOME} --cudnn_home ${PREFIX}"
else
  BUILD_ARGS=""
fi


python tools/ci_build/build.py \
    --enable_lto \
    --build_dir build-ci \
    --use_full_protobuf \
    ${CUDA_ARGS} \
    --cmake_extra_defines ${CMAKE_CUDA_EXTRA_DEFINES} Protobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc Protobuf_INCLUDE_DIR=$PREFIX/include "onnxruntime_PREFER_SYSTEM_LIB=ON" onnxruntime_USE_COREML=OFF CMAKE_PREFIX_PATH=$PREFIX CMAKE_INSTALL_PREFIX=$PREFIX \
    --cmake_generator Ninja \
    --build_wheel \
    --config Release \
    --update \
    --build \
    --skip_submodule_sync \
    ${BUILD_ARGS}

cp build-ci/Release/dist/onnxruntime-*.whl onnxruntime-${PKG_VERSION}-py3-none-any.whl
python -m pip install onnxruntime-${PKG_VERSION}-py3-none-any.whl
