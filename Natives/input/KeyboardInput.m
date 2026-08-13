#import "KeyboardInput.h"
#import "../utils.h"

#include "../glfw_keycodes.h"

@implementation KeyboardInput

int keycodeTable[UIKeyboardHIDUsageKeyboardRightGUI+1];
static BOOL pressedKeyTable[UIKeyboardHIDUsageKeyboardRightGUI+1];

static NSUInteger keyboardTableSize(void) {
    return sizeof(keycodeTable) / sizeof(keycodeTable[0]);
}

static char currentKeyboardModifiers(void) {
    char modifiers = 0;
    if (pressedKeyTable[UIKeyboardHIDUsageKeyboardCapsLock]) modifiers |= GLFW_MOD_CAPS_LOCK;
    if (pressedKeyTable[UIKeyboardHIDUsageKeyboardLeftShift] || pressedKeyTable[UIKeyboardHIDUsageKeyboardRightShift]) modifiers |= GLFW_MOD_SHIFT;
    if (pressedKeyTable[UIKeyboardHIDUsageKeyboardLeftAlt] || pressedKeyTable[UIKeyboardHIDUsageKeyboardRightAlt]) modifiers |= GLFW_MOD_ALT;
    if (pressedKeyTable[UIKeyboardHIDUsageKeyboardLeftControl] || pressedKeyTable[UIKeyboardHIDUsageKeyboardRightControl]) modifiers |= GLFW_MOD_CONTROL;
    return modifiers;
}

+ (void)initKeycodeTable {
    for (int i = UIKeyboardHIDUsageKeyboardA; i <= UIKeyboardHIDUsageKeyboardZ; i++) {
        keycodeTable[i] = i - UIKeyboardHIDUsageKeyboardA + GLFW_KEY_A;
    }

    // 0-9 keys
    keycodeTable[UIKeyboardHIDUsageKeyboard0] = GLFW_KEY_0;
    for (int i = UIKeyboardHIDUsageKeyboard1; i <= UIKeyboardHIDUsageKeyboard9; i++) {
        keycodeTable[i] = i - UIKeyboardHIDUsageKeyboard1 + GLFW_KEY_1;
    }

    // Arrow keys
    keycodeTable[UIKeyboardHIDUsageKeyboardUpArrow] = GLFW_KEY_DPAD_UP;
    keycodeTable[UIKeyboardHIDUsageKeyboardDownArrow] = GLFW_KEY_DPAD_DOWN;
    keycodeTable[UIKeyboardHIDUsageKeyboardLeftArrow] = GLFW_KEY_DPAD_LEFT;
    keycodeTable[UIKeyboardHIDUsageKeyboardRightArrow] = GLFW_KEY_DPAD_RIGHT;

    keycodeTable[UIKeyboardHIDUsageKeyboardComma] = GLFW_KEY_COMMA;
    keycodeTable[UIKeyboardHIDUsageKeyboardPeriod] = GLFW_KEY_PERIOD;

    // Alt keys
    keycodeTable[UIKeyboardHIDUsageKeyboardLeftAlt] = GLFW_KEY_LEFT_ALT;
    keycodeTable[UIKeyboardHIDUsageKeyboardRightAlt] = GLFW_KEY_RIGHT_ALT;

    // Control keys
    keycodeTable[UIKeyboardHIDUsageKeyboardLeftControl] = GLFW_KEY_LEFT_CONTROL;
    keycodeTable[UIKeyboardHIDUsageKeyboardRightControl] = GLFW_KEY_RIGHT_CONTROL;

    // Shift keys
    keycodeTable[UIKeyboardHIDUsageKeyboardLeftShift] = GLFW_KEY_LEFT_SHIFT;
    keycodeTable[UIKeyboardHIDUsageKeyboardRightShift] = GLFW_KEY_RIGHT_SHIFT;

    // Bracket keys
    keycodeTable[UIKeyboardHIDUsageKeyboardOpenBracket] = GLFW_KEY_LEFT_BRACKET;
    keycodeTable[UIKeyboardHIDUsageKeyboardCloseBracket] = GLFW_KEY_RIGHT_BRACKET;

    // Slash keys
    keycodeTable[UIKeyboardHIDUsageKeyboardSlash] = GLFW_KEY_SLASH;
    keycodeTable[UIKeyboardHIDUsageKeyboardBackslash] = GLFW_KEY_BACKSLASH;

    // Page keys
    keycodeTable[UIKeyboardHIDUsageKeyboardPageUp] = GLFW_KEY_PAGE_UP;
    keycodeTable[UIKeyboardHIDUsageKeyboardPageDown] = GLFW_KEY_PAGE_DOWN;

    // Some other keys
    keycodeTable[UIKeyboardHIDUsageKeyboardHome] = GLFW_KEY_HOME;
    keycodeTable[UIKeyboardHIDUsageKeyboardEscape] = GLFW_KEY_ESCAPE;
    keycodeTable[UIKeyboardHIDUsageKeyboardTab] = GLFW_KEY_TAB;
    keycodeTable[UIKeyboardHIDUsageKeyboardReturnOrEnter] = GLFW_KEY_ENTER;
    keycodeTable[UIKeyboardHIDUsageKeyboardSpacebar] = GLFW_KEY_SPACE;
    keycodeTable[UIKeyboardHIDUsageKeyboardDeleteOrBackspace] = GLFW_KEY_BACKSPACE;
    keycodeTable[UIKeyboardHIDUsageKeyboardDeleteForward] = GLFW_KEY_DELETE;
    keycodeTable[UIKeyboardHIDUsageKeyboardGraveAccentAndTilde] = GLFW_KEY_GRAVE_ACCENT;

    keycodeTable[UIKeyboardHIDUsageKeyboardHyphen] = GLFW_KEY_MINUS;
    keycodeTable[UIKeyboardHIDUsageKeyboardEqualSign] = GLFW_KEY_EQUAL;
    keycodeTable[UIKeyboardHIDUsageKeyboardSemicolon] = GLFW_KEY_SEMICOLON;
    keycodeTable[UIKeyboardHIDUsageKeyboardQuote] = GLFW_KEY_APOSTROPHE;
    keycodeTable[UIKeyboardHIDUsageKeyboardEnd] = GLFW_KEY_END;
    keycodeTable[UIKeyboardHIDUsageKeyboardInsert] = GLFW_KEY_INSERT;
    keycodeTable[UIKeyboardHIDUsageKeyboardPrintScreen] = GLFW_KEY_PRINT_SCREEN;
    keycodeTable[UIKeyboardHIDUsageKeyboardPause] = GLFW_KEY_PAUSE;
    keycodeTable[UIKeyboardHIDUsageKeyboardLeftGUI] = GLFW_KEY_LEFT_SUPER;
    keycodeTable[UIKeyboardHIDUsageKeyboardRightGUI] = GLFW_KEY_RIGHT_SUPER;
    keycodeTable[UIKeyboardHIDUsageKeypadPeriod] = GLFW_KEY_NUMPAD_DECIMAL;

    // Lock keys
    keycodeTable[UIKeyboardHIDUsageKeyboardCapsLock] = GLFW_KEY_CAPS_LOCK;
    keycodeTable[UIKeyboardHIDUsageKeypadNumLock] = GLFW_KEY_NUM_LOCK;
    keycodeTable[UIKeyboardHIDUsageKeyboardScrollLock] = GLFW_KEY_SCROLL_LOCK;

    // Numpad keys
    keycodeTable[UIKeyboardHIDUsageKeypadSlash] = GLFW_KEY_NUMPAD_DIVIDE;
    keycodeTable[UIKeyboardHIDUsageKeypadAsterisk] = GLFW_KEY_NUMPAD_MULTIPLY;
    keycodeTable[UIKeyboardHIDUsageKeypadHyphen] = GLFW_KEY_NUMPAD_SUBTRACT;
    keycodeTable[UIKeyboardHIDUsageKeypadPlus] = GLFW_KEY_NUMPAD_ADD;
    keycodeTable[UIKeyboardHIDUsageKeypadEnter] = GLFW_KEY_NUMPAD_ENTER;
    keycodeTable[UIKeyboardHIDUsageKeypadEqualSign] = GLFW_KEY_NUMPAD_EQUAL;
    keycodeTable[UIKeyboardHIDUsageKeypad0] = GLFW_KEY_NUMPAD_0;
    for (int i = UIKeyboardHIDUsageKeypad1; i <= UIKeyboardHIDUsageKeypad9; i++) {
        keycodeTable[i] = i - UIKeyboardHIDUsageKeypad1 + GLFW_KEY_NUMPAD_1;
    }

    // Function keys
    for (int i = UIKeyboardHIDUsageKeyboardF1; i <= UIKeyboardHIDUsageKeyboardF12; i++) {
        keycodeTable[i] = i - UIKeyboardHIDUsageKeyboardF1 + GLFW_KEY_F1;
    }
}

+ (BOOL)sendKeyEvent:(UIKey *)key down:(BOOL)isDown {
    char modifiers = 0;

    // convert UIKey's modifiers to GLFW
    if (key.modifierFlags & UIKeyModifierAlphaShift) {
        modifiers |= GLFW_MOD_CAPS_LOCK;
    }
    if (key.modifierFlags & UIKeyModifierShift) {
        modifiers |= GLFW_MOD_SHIFT;
    }
    if (key.modifierFlags & UIKeyModifierAlternate) {
        modifiers |= GLFW_MOD_ALT;
    }
    if (key.modifierFlags & UIKeyModifierControl) {
        modifiers |= GLFW_MOD_CONTROL;
    }

    NSUInteger hidCode = key.keyCode;
    if (hidCode >= keyboardTableSize()) {
        NSLog(@"KeyboardInput: Ignoring out-of-range HID key %lu", (unsigned long)hidCode);
        return NO;
    }

    int keycode = keycodeTable[hidCode];
    BOOL stateChanged = pressedKeyTable[hidCode] != isDown;
    pressedKeyTable[hidCode] = isDown;
    if (keycode != 0 && stateChanged) {
        CallbackBridge_nativeSendKey(keycode, 0 /* scancode */, isDown, modifiers);
    } else if (keycode == 0) {
        NSLog(@"KeyboardInput: Unhandled key %lu", (unsigned long)hidCode);
    }

    // key.characters.length < 11: skip sending characters if the string starts with UIKeyInput
    // GameController has no layout-aware text, so let UIKit deliver characters
    // even when it follows a de-duplicated GC key event.
    if (isDown && key.characters.length < 11) {
        for (int i = 0; i < key.characters.length; i++) {
            int keychar = [key.characters characterAtIndex:i];
            CallbackBridge_nativeSendCharMods(keychar, modifiers);
            CallbackBridge_nativeSendChar(keychar);
        }
    }

    return keycode != 0 || isDown;
}

+ (BOOL)sendGCKeyCode:(NSInteger)keyCode down:(BOOL)isDown {
    if (keyCode < 0 || (NSUInteger)keyCode >= keyboardTableSize()) {
        NSLog(@"KeyboardInput: Ignoring out-of-range GC key %ld", (long)keyCode);
        return NO;
    }

    NSUInteger hidCode = (NSUInteger)keyCode;
    int glfwKey = keycodeTable[hidCode];
    if (glfwKey == 0) {
        NSLog(@"KeyboardInput: Unhandled GC key %ld", (long)keyCode);
        return NO;
    }

    // UIKit and GameController can report the same physical event on iOS 26.
    // Keep one shared state table so it is delivered exactly once.
    if (pressedKeyTable[hidCode] == isDown) return YES;
    pressedKeyTable[hidCode] = isDown;
    CallbackBridge_nativeSendKey(glfwKey, 0, isDown, currentKeyboardModifiers());
    return YES;
}

+ (void)resetPressedKeys {
    for (NSUInteger hidCode = 0; hidCode < keyboardTableSize(); hidCode++) {
        if (pressedKeyTable[hidCode] && keycodeTable[hidCode] != 0) {
            CallbackBridge_nativeSendKey(keycodeTable[hidCode], 0, NO, 0);
        }
        pressedKeyTable[hidCode] = NO;
    }
}

@end
