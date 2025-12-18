#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <stdbool.h>
#include <signal.h>
#include <locale.h>

#define TARGET_FPS 60
#define FRAME_TIME_US 16666
#define MAX_TEXT_LENGTH 512
#define CHECK_INTERVAL 15  // Увеличил частоту проверки
#define ANIM_SPEED 20      // Увеличил скорость анимации

volatile sig_atomic_t running = 1;

void handle_signal(int sig) {
    running = 0;
}

typedef struct {
    char target[MAX_TEXT_LENGTH];
    char current[MAX_TEXT_LENGTH];
    int anim_pos;
    int text_len;
    int frames_since_check;
    bool needs_update;
    bool is_animating;
    bool music_playing;
} AnimationState;

void init_state(AnimationState *state) {
    memset(state, 0, sizeof(AnimationState));
    state->frames_since_check = 0;
    state->needs_update = true;
    state->is_animating = false;
    state->music_playing = false;
}

// Функция выполнения команды
bool exec_shell_cmd(const char* cmd, char* output, size_t output_size) {
    if (cmd == NULL || output == NULL) return false;
    
    FILE* fp = popen(cmd, "r");
    if (fp == NULL) return false;
    
    bool success = false;
    if (fgets(output, output_size, fp) != NULL) {
        output[strcspn(output, "\n")] = 0;
        success = true;
    }
    
    pclose(fp);
    return success;
}

// Улучшенная проверка плееров
bool check_player_playing(const char* player_name) {
    char status_cmd[256];
    char status[32];
    
    snprintf(status_cmd, sizeof(status_cmd), 
             "playerctl -p %s status 2>/dev/null", player_name);
    
    if (!exec_shell_cmd(status_cmd, status, sizeof(status))) {
        return false;
    }
    
    return (strcmp(status, "Playing") == 0);
}

// Получаем трек от конкретного плеера
bool get_track_from_player(const char* player_name, char* buffer, size_t buffer_size) {
    char metadata_cmd[256];
    
    snprintf(metadata_cmd, sizeof(metadata_cmd),
             "playerctl -p %s metadata --format '{{artist}} - {{title}}' 2>/dev/null",
             player_name);
    
    if (!exec_shell_cmd(metadata_cmd, buffer, buffer_size)) {
        return false;
    }
    
    // Проверяем валидность
    if (strlen(buffer) == 0 || 
        strstr(buffer, "No player") != NULL ||
        strstr(buffer, "could not find") != NULL) {
        return false;
    }
    
    return true;
}

// Основная функция получения трека
bool get_current_track_all_players(char *buffer, size_t buffer_size) {
    char players[512];
    char track_info[MAX_TEXT_LENGTH];
    
    // Сначала пробуем Spotify напрямую (часто бывают проблемы)
    if (check_player_playing("spotify")) {
        if (get_track_from_player("spotify", track_info, sizeof(track_info))) {
            strncpy(buffer, track_info, buffer_size - 1);
            buffer[buffer_size - 1] = '\0';
            return true;
        }
    }
    
    // Получаем список всех плееров
    if (!exec_shell_cmd("playerctl --list-all 2>/dev/null", players, sizeof(players))) {
        return false;
    }
    
    if (strlen(players) == 0) {
        return false;
    }
    
    // Проверяем каждого плеера
    char* player = strtok(players, " \n");
    while (player != NULL) {
        // Пропускаем Spotify, если уже проверяли
        if (strstr(player, "spotify") != NULL) {
            player = strtok(NULL, " \n");
            continue;
        }
        
        if (check_player_playing(player)) {
            if (get_track_from_player(player, track_info, sizeof(track_info))) {
                strncpy(buffer, track_info, buffer_size - 1);
                buffer[buffer_size - 1] = '\0';
                return true;
            }
        }
        player = strtok(NULL, " \n");
    }
    
    // Альтернативный метод для Spotify (иногда нужно по-другому)
    if (exec_shell_cmd("playerctl -p spotify.%* status 2>/dev/null", players, sizeof(players))) {
        if (strstr(players, "Playing")) {
            if (exec_shell_cmd("playerctl -p spotify.%* metadata --format '{{artist}} - {{title}}' 2>/dev/null", 
                              buffer, buffer_size)) {
                if (strlen(buffer) > 0 && !strstr(buffer, "No player")) {
                    return true;
                }
            }
        }
    }
    
    // Пробуем MPD
    char mpd_status[256];
    if (exec_shell_cmd("mpc status 2>/dev/null", mpd_status, sizeof(mpd_status))) {
        if (strstr(mpd_status, "[playing]")) {
            if (exec_shell_cmd("mpc current 2>/dev/null", buffer, buffer_size)) {
                if (strlen(buffer) > 0) {
                    return true;
                }
            }
        }
    }
    
    // Последняя попытка: любой играющий плеер
    if (exec_shell_cmd("playerctl --all-players metadata --format '{{artist}} - {{title}}' 2>/dev/null", 
                      buffer, buffer_size)) {
        if (strlen(buffer) > 0 && !strstr(buffer, "No player")) {
            // Проверяем статус
            char status[32];
            if (exec_shell_cmd("playerctl --all-players status 2>/dev/null", status, sizeof(status))) {
                if (strcmp(status, "Playing") == 0) {
                    return true;
                }
            }
        }
    }
    
    return false;
}

// Простой набор символов для анимации
const char* get_random_char() {
    static const char* chars[] = {
        "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "+", "-", "=",
        "[", "]", "{", "}", "|", ";", ":", ",", ".", "<", ">", "?", "/", "~", "`",
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М",
        "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я",
        "░", "▒", "▓", "│", "┤", "╡", "╢", "╖", "╕", "╣", "║", "╗", "╝", "╜", "╛", "┐", "└", "┴", "┬",
        "├", "─", "┼", "╞", "╟", "╚", "╔", "╩", "╦", "╠", "═", "╬", "╧", "╨", "╤", "╥", "╙", "╘", "╒",
        "╓", "╫", "╪", "┘", "┌", "█", "▄", "▌", "▐", "▀",
        "♪", "♫", "🎵", "🎶", "🎧", "📻", "🔊"
    };
    
    static const int char_count = sizeof(chars) / sizeof(chars[0]);
    return chars[rand() % char_count];
}

// Обновление анимации (ИСПРАВЛЕНО: не прекращает вывод после анимации)
void update_animation(AnimationState *state) {
    // Проверяем, нужно ли обновить трек (чаще)
    state->frames_since_check++;
    if (state->frames_since_check >= CHECK_INTERVAL) {
        state->frames_since_check = 0;
        state->needs_update = true;
    }
    
    // Обновляем трек если нужно
    if (state->needs_update) {
        state->needs_update = false;
        
        char new_track[MAX_TEXT_LENGTH];
        bool has_music = get_current_track_all_players(new_track, sizeof(new_track));
        state->music_playing = has_music;
        
        if (has_music) {
            // Формируем строку с иконкой
            char with_icon[MAX_TEXT_LENGTH];
            int written = snprintf(with_icon, sizeof(with_icon), "󰝚 %s", new_track);
            if (written >= (int)sizeof(with_icon)) {
                with_icon[sizeof(with_icon) - 1] = '\0';
            }
            
            // Если трек изменился - начинаем новую анимацию
            if (strcmp(state->target, with_icon) != 0) {
                strncpy(state->target, with_icon, MAX_TEXT_LENGTH - 1);
                state->target[MAX_TEXT_LENGTH - 1] = '\0';
                state->text_len = strlen(state->target);
                state->anim_pos = 0;
                state->is_animating = true;
                
                // Генерируем первый кадр анимации
                for (int i = 0; i < state->text_len && i < MAX_TEXT_LENGTH - 1; i++) {
                    if (i == 0) {
                        state->current[i] = state->target[i];
                    } else {
                        const char* rand_char = get_random_char();
                        state->current[i] = rand_char[0];
                    }
                }
                state->current[state->text_len] = '\0';
            }
        } else {
            // Нет музыки
            state->target[0] = '\0';
            state->current[0] = '\0';
            state->text_len = 0;
            state->is_animating = false;
        }
    }
    
    // Если музыка не играет
    if (!state->music_playing) {
        state->current[0] = '\0';
        return;
    }
    
    // ОЧЕНЬ ВАЖНО: Даже если анимация завершена, продолжаем выводить текст
    if (!state->is_animating) {
        // Анимация завершена, но музыка играет - показываем полный текст
        if (strlen(state->target) > 0) {
            strncpy(state->current, state->target, MAX_TEXT_LENGTH - 1);
            state->current[MAX_TEXT_LENGTH - 1] = '\0';
        }
        return;
    }
    
    // Обновляем анимацию (только если она еще идет)
    if (state->anim_pos < state->text_len) {
        int chars_to_animate = 3; // Быстрее
        
        for (int i = 0; i < state->text_len && i < MAX_TEXT_LENGTH - 1; i++) {
            if (i < state->anim_pos) {
                state->current[i] = state->target[i];
            } else if (i < state->anim_pos + chars_to_animate) {
                state->current[i] = state->target[i];
            } else {
                const char* rand_char = get_random_char();
                state->current[i] = rand_char[0];
            }
        }
        state->current[state->text_len] = '\0';
        
        state->anim_pos += chars_to_animate;
        if (state->anim_pos >= state->text_len) {
            state->anim_pos = state->text_len;
            state->is_animating = false;
            // После завершения анимации показываем полный текст
            strcpy(state->current, state->target);
        }
    }
}

int main() {
    setlocale(LC_ALL, "");
    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);
    srand(time(NULL));
    
    AnimationState state;
    init_state(&state);
    
    int frame = 0;
    int output_count = 0;
    
    while (running) {
        update_animation(&state);
        
        // ВСЕГДА выводим что-то на каждом кадре
        if (state.music_playing && strlen(state.current) > 0) {
            printf("%s\n", state.current);
            output_count++;
        } else {
            printf("\n");
        }
        fflush(stdout);
        
        usleep(FRAME_TIME_US);
        frame++;
        
        // Отладочная информация (можно закомментировать)
        if (frame % 120 == 0) { // Каждые 2 секунды
            fprintf(stderr, "Frame: %d, Outputs: %d, Playing: %d, Animating: %d\n", 
                    frame, output_count, state.music_playing, state.is_animating);
        }
    }
    
    return 0;
}
