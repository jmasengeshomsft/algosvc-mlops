#include <jni.h>
#include <vector>
#include <cmath>

extern "C" JNIEXPORT jfloatArray JNICALL
Java_com_acme_NativeKernels_fastOp(JNIEnv* env, jclass,
                                   jfloatArray jin, jfloat jscale) {
    jsize n = env->GetArrayLength(jin);
    jfloat* pin = env->GetFloatArrayElements(jin, nullptr);
    float scale = static_cast<float>(jscale);

    std::vector<float> out(n);
    for (jsize i = 0; i < n; ++i) {
        float x = pin[i] * scale;
        float y = 1.0f / (1.0f + std::exp(-x)); // sigmoid
        out[i] = y;
    }

    env->ReleaseFloatArrayElements(jin, pin, JNI_ABORT);

    jfloatArray jout = env->NewFloatArray(n);
    env->SetFloatArrayRegion(jout, 0, n, out.data());
    return jout;
}