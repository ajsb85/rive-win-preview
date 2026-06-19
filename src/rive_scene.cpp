// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Alexander Salas Bastidas <ajsb85@firechip.dev>
//
// rive_scene.cpp
#include "rive_scene.hpp"

#include <windows.h>
#include <excpt.h>
#include <functional>

#include "rive/math/aabb.hpp"
#include "rive/layout.hpp"

using namespace rive;

namespace rivepeek {

namespace {
// Treat a hardware fault (e.g. a malformed embedded font tripping the shaper) as
// recoverable; let genuine C++ exceptions propagate.
int faultFilter(unsigned int code) {
    return (code == EXCEPTION_ACCESS_VIOLATION ||
            code == EXCEPTION_STACK_OVERFLOW ||
            code == EXCEPTION_ILLEGAL_INSTRUCTION ||
            code == EXCEPTION_INT_DIVIDE_BY_ZERO)
               ? EXCEPTION_EXECUTE_HANDLER
               : EXCEPTION_CONTINUE_SEARCH;
}

// Run `fn` under structured exception handling, returning false if a hardware
// fault was caught. This frame holds no C++ objects that need unwinding, so the
// __try/__except is legal under /EHsc. Defense-in-depth: the handler already
// runs inside prevhost.exe, but a guarded fault degrades to a blank preview
// instead of taking down the host process or a thumbnail-cache host.
bool guard(const std::function<void()>& fn) {
    __try {
        fn();
        return true;
    } __except (faultFilter(GetExceptionCode())) {
        return false;
    }
}
} // namespace

RiveScene::~RiveScene() { teardown(); }

void RiveScene::teardown() {
    guard([&] {
        m_animation.reset();
        m_stateMachine.reset();
        m_artboard.reset(); // ~ArtboardInstance can fault on scripting objects
        m_file = nullptr;
    });
}

bool RiveScene::load(const uint8_t* data, size_t size) {
    m_error.clear();
    teardown();

    if (!data || size < 4) {
        m_error = "empty or truncated file";
        return false;
    }

    // Import + instantiate under SEH: a malformed embedded font can corrupt the
    // shaper and fault while settling the initial pose.
    ImportResult result = ImportResult::malformed;
    const bool ok = guard([&] {
        m_file = File::import(Span<const uint8_t>(data, size), &m_factory, &result);
        if (result != ImportResult::success || !m_file) return;
        m_artboard = m_file->artboardDefault();
        if (!m_artboard) return;
        // Prefer the default state machine; fall back to the first animation.
        m_stateMachine = m_artboard->defaultStateMachine();
        if (!m_stateMachine && m_artboard->animationCount() > 0) {
            m_animation = m_artboard->animationAt(0);
        }
        m_artboard->advance(0.0f); // settle the initial pose
    });

    if (!ok) {
        teardown();
        m_error = "aborted on a hardware fault while loading (guarded)";
        return false;
    }
    if (!m_file || result != ImportResult::success) {
        switch (result) {
            case ImportResult::unsupportedVersion:
                m_error = "unsupported Rive version (runtime is major 7)";
                break;
            case ImportResult::malformed:
                m_error = "malformed .riv file";
                break;
            default:
                m_error = "failed to import .riv file";
                break;
        }
        return false;
    }
    if (!m_artboard) {
        m_error = "file has no artboard";
        return false;
    }
    return true;
}

float RiveScene::width() const {
    return m_artboard ? m_artboard->bounds().width() : 0.0f;
}
float RiveScene::height() const {
    return m_artboard ? m_artboard->bounds().height() : 0.0f;
}

void RiveScene::advance(float dt) {
    if (!m_artboard) return;
    const bool ok = guard([&] {
        if (m_stateMachine) {
            m_stateMachine->advanceAndApply(dt);
        } else if (m_animation) {
            m_animation->advanceAndApply(dt);
        } else {
            m_artboard->advance(dt);
        }
    });
    if (!ok) {
        // Tear the scene down so we stop animating a corrupted state.
        teardown();
        m_error = "aborted on a hardware fault while advancing (guarded)";
    }
}

void RiveScene::draw(D2DRenderer& renderer, float frameW, float frameH) {
    if (!m_artboard) return;
    guard([&] {
        renderer.save();
        renderer.align(Fit::contain, Alignment::center,
                       AABB(0.0f, 0.0f, frameW, frameH), m_artboard->bounds());
        m_artboard->draw(&renderer);
        renderer.restore();
    });
}

} // namespace rivepeek
