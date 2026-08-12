//
// Created by BZLZHH on 2025/1/26.
//

#include <algorithm>
#include <cctype>
#include <limits>
#include "shader.h"

#include <GL/gl.h>
#include "log.h"
#include "program.h"
#include "../gles/loader.h"
#include "../includes.h"
#include "glsl/glsl_for_es.h"
#include "../config/settings.h"
#include "FSR1/FSR1.h"

#define DEBUG 0

struct shader_t shaderInfo;

UnorderedMap<GLuint, bool> shader_map_is_sampler_buffer_emulated;
UnorderedMap<GLuint, bool> shader_map_is_atomic_counter_emulated;

static std::string canonicalize_essl_source(std::string source, unsigned int es_version) {
    // ANGLE requires the version directive to be the first token. Remove data
    // which can accidentally terminate or prefix a cached/generated C string.
    source.erase(std::remove(source.begin(), source.end(), '\0'), source.end());
    source.erase(std::remove(source.begin(), source.end(), '\r'), source.end());

    const size_t version_pos = source.find("#version");
    if (version_pos != std::string::npos) {
        const size_t version_end = source.find('\n', version_pos);
        source.erase(0, version_end == std::string::npos ? source.size() : version_end + 1);
    }

    while (!source.empty() && std::isspace(static_cast<unsigned char>(source.front()))) {
        source.erase(source.begin());
    }

    unsigned int target_version = 300;
    if (es_version >= 320) target_version = 320;
    else if (es_version >= 310) target_version = 310;

    return "#version " + std::to_string(target_version) + " es\n" + source;
}

bool can_run_essl3(unsigned int esversion, const char *glsl) {
    if (strncmp(glsl, "#version 100", 12) == 0) {
        return true; 
    }

    unsigned int glsl_version = 0;
    if (strncmp(glsl, "#version 300 es", 15) == 0) {
        glsl_version = 300;
    } else if (strncmp(glsl, "#version 310 es", 15) == 0) {
        glsl_version = 310;
    } else if (strncmp(glsl, "#version 320 es", 15) == 0) {
        glsl_version = 320;
    } else {
        return false;
    }
    return esversion >= glsl_version;
}

bool is_direct_shader(const char *glsl)
{
    bool es3_ability = can_run_essl3(hardware->es_version, glsl);
    return es3_ability;
}

bool check_if_sampler_buffer_used(std::string str) {
    return str.find("samplerBuffer") != std::string::npos;
}

void glShaderSource(GLuint shader, GLsizei count, const GLchar *const* string, const GLint *length) {    
    LOG()
    shaderInfo.id = 0;
    shaderInfo.converted = "";
    shaderInfo.frag_data_changed = 0;
    size_t l = 0;
    for (int i=0; i<count; i++) l+=(length && length[i] >= 0)?length[i]:strlen(string[i]);
    std::string glsl_src, essl_src;
    glsl_src.reserve(l + 1);
    if (length) {
        for (int i = 0; i < count; i++) {
            if(length[i] >= 0)
                glsl_src += std::string_view(string[i], length[i]);
            else
                glsl_src += string[i];
        }
    } else {
        for (int i = 0; i < count; i++) {
            glsl_src += string[i];
        }
    }

    bool is_sampler_buffer_emulated = 
        hardware->emulate_texture_buffer && check_if_sampler_buffer_used(glsl_src);

    if(is_direct_shader(glsl_src.c_str())){
        LOG_D("[INFO] [Shader] Direct shader source: ")
        LOG_D("%s", glsl_src.c_str())
        essl_src = glsl_src;
    } else {
        int glsl_version = getGLSLVersion(glsl_src.c_str());
        LOG_D("[INFO] [Shader] Shader source: ")
        LOG_D("%s", glsl_src.c_str())
        GLint shaderType;
        GLES.glGetShaderiv(shader, GL_SHADER_TYPE, &shaderType);
		int return_code = 0;
        essl_src = GLSLtoGLSLES(glsl_src.c_str(), shaderType, hardware->es_version, glsl_version, return_code);
        if (return_code == 1) { //atomicCounterEmulated
			shader_map_is_atomic_counter_emulated[shader] = true;
			LOG_D("[INFO] [Shader] Atomic counter emulated in shader %d", shader)
        }

        if (essl_src.empty()) {
            LOG_E("Failed to convert shader %d.", shader)
            return;
        }
        essl_src = canonicalize_essl_source(std::move(essl_src), hardware->es_version);
        LOG_D("\n[INFO] [Shader] Converted Shader source: \n%s", essl_src.c_str())
    }
    if (!essl_src.empty()) {
        shaderInfo.id = shader;
        shaderInfo.converted = essl_src;
        const char* s[] = { essl_src.c_str() };
        if (essl_src.size() > static_cast<size_t>(std::numeric_limits<GLint>::max())) {
            LOG_E("Converted shader %d is too large.", shader)
            return;
        }
        const GLint source_length = static_cast<GLint>(essl_src.size());
        // The input strings were concatenated and translated into one buffer above.
        // Passing the original count makes GLES read past this one-element array.
        // Supplying the exact size also prevents an embedded/cache terminator from
        // truncating the #version line passed to ANGLE.
        GLES.glShaderSource(shader, 1, s, &source_length);
        if (hardware->emulate_texture_buffer)
            shader_map_is_sampler_buffer_emulated[shader] = is_sampler_buffer_emulated;
    }
    else
        LOG_E("Failed to convert glsl.")
    CHECK_GL_ERROR
}

void glGetShaderiv(GLuint shader, GLenum pname, GLint *params) {
    LOG()
    GLES.glGetShaderiv(shader, pname, params);
    if(global_settings.ignore_error >= IgnoreErrorLevel::Partial && pname == GL_COMPILE_STATUS && !*params) {
        GLchar infoLog[512];
        GLES.glGetShaderInfoLog(shader, 512, nullptr, infoLog);
        LOG_W_FORCE("Shader %d compilation failed: \n%s", shader, infoLog)
        LOG_W_FORCE("Now try to cheat.")
        *params = GL_TRUE;
    }
    CHECK_GL_ERROR
}

GLuint glCreateShader(GLenum shaderType) {
    if (global_settings.fsr1_setting != FSR1_Quality_Preset::Disabled && !fsrInitialized) {
        InitFSRResources();
    }

    LOG()
    LOG_D("glCreateShader(%s)", glEnumToString(shaderType))
    GLuint shader = GLES.glCreateShader(shaderType);
    if (shader != 0 && hardware->emulate_texture_buffer)
        shader_map_is_sampler_buffer_emulated[shader] = false;
    CHECK_GL_ERROR
    return shader;
}
