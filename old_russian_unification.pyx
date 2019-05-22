#cython: language_level=3, boundscheck=False
"""Функции, которые приводят графику двух словарей в единый формат

Как можно заметить, данный код сильно оптимизирован:
1) Регулярные выражение не используются.
2) Типы по возможности объявлены как статические.
3) Используются циклы while вместо for, так как while переводится в C без изменений, поэтому работает быстрее.
Примир компиляции начала цикла из функции unify_iotated в C:

/* "unification.pyx":150
 *     cdef int i = 0
 *     cdef int l = len(text)
 *     while i < l:             # <<<<<<<<<<<<<<
 *         if i + 1 == l:
 *             new_text += text[i]
 */
  while (1) {
    __pyx_t_3 = ((__pyx_v_i < __pyx_v_l) != 0);
    if (!__pyx_t_3) break;
"""
__author__ = "Michael Voronov, Anna Sorokina"
__license__ = "GPLv3"


iotated = 'юиѭѩѥꙓꙑ'
set1 = {'ш', 'щ', 'ж', 'ч', 'ц'}
set2 = 'аоєѹiѧѫѣъьѵѷ' + iotated
set3 = 'i' + iotated
set4 = 'цкнгшщзхфвпрлджчсмтб'


'''
┌———————————————┐
│ Общие функции │
└———————————————┘
——————————————————————————————————————————————————————————————————————————————————————————┐
'''

def strip_stuff(text):
    """Приводит в нижний регистр и убирает '|' и прочее."""
    text = text.lower()
    cdef unicode new_text = ''
    cdef int i = 0
    cdef int l = len(text)
    while i < l:
        if text[i] == ('|'):
            i += 1
        elif text[i] == '.':
            i += 1
        elif text[i] == ',':
            i += 1
        elif text[i] == '!':
            i += 1
        elif text[i] == '?':
            i += 1
        elif text[i] == '-':
            i += 1
        elif text[i] == ' ':
            break
        else:
            new_text += text[i]
            i += 1
    return new_text


def unify_various_symbols(text):
    """Унифицирует разные варианты."""
    mapping = {
        'е': 'є',
        'э': 'є',
        'ѥ': 'є',
        'у': 'ѹ',
        'ꙋ': 'ѹ',
        'Ꙋ': 'ѹ',
        'ѡ': 'о',
        'ѿ': 'от',
        'ї': 'и',
        'і': 'и',
        'ы': 'ꙑ',
        'ꙗ': 'ѧ',
        'я': 'ѧ',
        'ꙁ': 'з',
        'ѕ': 'з',
        'ѳ': 'ф',
        'ѯ': 'кс',
        'ѱ': 'пс',
        'ꙩ': 'о',
        'ꙫ': 'о',
        'ꙭ': 'о',
        'ꚙ': 'о',
        'ꚛ': 'о',
        'ꙮ': 'о',
        'ѽ': 'о',
        '҃': '',
        'й': 'и'
    }
    cdef unicode new_text = ''
    cdef int i = 0
    cdef int l = len(text)
    while i < l:
        if i + 1 == l:
            if text[i] in mapping:
                new_text += mapping[text[i]]
            else:
                new_text += text[i]
            i += 1
        else:
            if text[i] == 'о' and text[i+1] == 'у':
                new_text += 'ѹ'
                i += 2
            elif text[i] == 'ъ' and (text[i+1] == 'i' or text[i+1] == 'ї'):
                new_text += 'ꙑ'
                i += 2
            elif text[i] in mapping:
                new_text += mapping[text[i]]
                i += 1
            else:
                new_text += text[i]
                i += 1
    return new_text


def unify_final_shwa(text):
    """Приводит 'ъ' и 'ь' в конце к 'ъ'
    
    Не используется.
    """
    if text.endswith('ь'):
        text = text[:-1] + 'ъ'
    return text


def unify_vowels_after_set1(text):
    """Переводит нестрого йотированные после 'ш', 'щ', 'ж', 'жд', 'ч', 'ц' в строго не-йотированные.
    
    Мутная формулировка, но речь идёт о конкретных гласных и их фонологической релевантности после шипящих:
    ѧ/ѩ/а -> ѧ
    ѹ/ѫ/ѭ -> ѹ
    """
    mapping = {
        'а': 'ѧ',
        'ѩ': 'ѧ',
        'ю': 'ѹ',
        'ѫ': 'ѹ',
        'ѭ': 'ѹ'
    }
    cdef unicode new_text = ''
    cdef int l = len(text)
    cdef int i = 0
    while i < l:
        if i + 1 == l:
            new_text += text[i]
            i += 1
        else:
            if text[i] in set1 and text[i+1] in mapping:
                new_text += text[i] + mapping[text[i+1]]
                i += 2
            elif text[i] == 'ж' and text[i+1] == 'д':
                if i + 2 == l:
                    new_text += text[i]
                    i += 1
                else:
                    if text[i + 2] in mapping:
                        new_text += text[i] + text[i+1] + mapping[text[i+2]]
                        i += 3
                    else:
                        new_text += text[i]
                        i += 1
            else:
                new_text += text[i]
                i += 1
    return new_text


def unify_iotated(text):
    """Убирает йотацию в начале слова и после гласных.
    
    Такая мера может показаться странной, так как в современном русском языке различение йотированных и нейотированных
    в позиции начала слова релевантно (ср. "агнец" и "ягнёнок"). Однако, такое различение происходит прежде всего из противопоставления
    исконных слов и церковнославянских заимствований (ср. "аз" и "я"). В то время церковнославянский широко использовался
    носителями древнерусского, но чёткого различения не существовало.
    """
    mapping = {
        'ю': 'ѹ',
        'ѩ': 'а',
        'ѧ': 'а',
        'ѭ': 'ѫ',
        'ꙓ': 'ѣ'
    }
    cdef unicode new_text = ''
    cdef int i = 0
    cdef int l = len(text)
    while i < l:
        if i + 1 == l:
            new_text += text[i]
            i += 1
        else:
            if text[i] in set2 and text[i+1] in mapping:
                new_text += text[i] + mapping[text[i+1]]
                i += 2
            elif i == 0 and text[i] in mapping:
                new_text += mapping[text[0]]
                i += 1
            else:
                new_text += text[i]
                i += 1
    return new_text


def unify_i_and_front_shwa(text):
    """Превращает 'ь' после 'i' и йотированных в 'и'"""
    cdef unicode new_text = ''
    cdef int i = 0
    cdef int l = len(text)
    while i < l:
        if i + 1 == l:
            new_text += text[i]
            i += 1
        else:
            if text[i] in set3 and text[i+1] == 'ь':
                new_text += text[i] + 'и'
                i += 2
            else:
                new_text += text[i]
                i += 1
    return new_text


def ie(text):
    """Заменяет ье на ие"""
    cdef unicode new_text = ''
    new_text = text.replace('ьє', 'иє')
    return new_text


'''
——————————————————————————————————————————————————————————————————————————————————————————┘
┌————————————————————————————————————————————————————┐
│ Функции, связанные с сочетаниями плавных и гласных │
└————————————————————————————————————————————————————┘
——————————————————————————————————————————————————————————————————————————————————————————┐
'''

def unify_r_and_l_with_shwas1(text):
    """Превращает сочетание 'согласный + р/л + ь/ъ + согласный' в 'согласный + є/о + р/л + согласный'"""
    cdef unicode new_text = ''
    cdef int i = 0
    cdef int l = len(text)
    while i < l:
        if i + 3 >= l:
            new_text += text[i]
            i += 1
        else:
            if text[i] in set4 and text[i+1] in 'рл' and text[i+2] in 'ъь' and text[i+3] in set4:
                '''
                if text[i+2] == 'ь':
                    new_text += text[i] + 'є' + text[i+1] + text[i+3]
                else:
                    new_text += text[i] + 'о' + text[i+1] + text[i+3]
                '''
                new_text += text[i] + 'є' + text[i+1] + text[i+3]
                i += 4
            else:
                new_text += text[i]
                i += 1
    return new_text



def unify_r_and_l_with_shwas2(text):
    """Превращает сочетание 'согласный + ь/ъ + р/л + согласный' в 'согласный + є/о + р/л + согласный'"""
    cdef unicode new_text = ''
    cdef int i = 0
    cdef int l = len(text)
    while i < l:
        if i + 3 >= l:
            new_text += text[i]
            i += 1
        else:
            if text[i] in set4 and text[i+1] in 'ъь' and text[i+2] in 'рл' and text[i+3] in set4:
                if text[i+1] == 'ь':
                    new_text += text[i] + 'є' + text[i+2] + text[i+3]
                else:
                    new_text += text[i] + 'о' + text[i+2] + text[i+3]
                i += 4
            else:
                new_text += text[i]
                i += 1
    return new_text


def unify_r_and_l_with_yat(text):
    """Превращает сочетание 'согласный + р/л + ѣ + согласный' в 'согласный + р/л + є + согласный'"""
    cdef unicode new_text = ''
    cdef int i = 0
    cdef int l = len(text)
    while i < l:
        if i + 3 >= l:
            new_text += text[i]
            i += 1
        else:
            if text[i] in set4 and text[i+1] in 'рл' and text[i+2] in 'ѣ' and text[i+3] in set4:
                new_text += text[i] + text[i+1] + 'є' + text[i+3]
                i += 4
            else:
                new_text += text[i]
                i += 1
    return new_text


'''
——————————————————————————————————————————————————————————————————————————————————————————┘
┌————————————————————————————┐
│ Функции для редуцированных │
└————————————————————————————┘
——————————————————————————————————————————————————————————————————————————————————————————┐
'''


def drop_shwas(text):
    """Положить редуцированные."""
    text = list(text)
    cdef int i = len(text) - 1
    drop_next = True
    while i >= 0:
        if text[i] in 'ъь':
            if drop_next:
                text.pop(i)
                drop_next = False
            else:
                if text[i] == 'ь':
                    text[i] = 'є'
                else:
                    text[i] = 'о'
                drop_next = True
        elif text[i] in set2:
            drop_next = True
        i -= 1
    return ''.join(text)


def add_shwas(text):
    """Добавим редуцированные после ВСЕХ согласных не перед гласными."""
    cdef unicode new_text = ''
    cdef int i = 0
    cdef int l = len(text)
    while i < l:
        if i + 1 == l:
            if text[i] in set4:
                new_text += text[i] + 'ъ'
            else:
                new_text += text[i]
        else:
            if text[i] in set4 and not text[i + 1] in set2:
                new_text += text[i] + 'ъ'
            else:
                new_text += text[i]
        i += 1
    return new_text


def replace_shwas(text):
    """Меняет редуцированные на є/о"""
    cdef unicode new_text = ''
    cdef int i = 0
    cdef int l = len(text)
    while i < l:
        if text[i] == 'ь':
            new_text += 'є'
        elif text[i] == 'ъ':
            new_text += 'о'
        else:
            new_text += text[i]
        i += 1
    return new_text


def mix_shwas(text):
    """Приводит редуцированные к ъ."""
    cdef unicode new_text = ''
    cdef int i = 0
    cdef int l = len(text)
    while i < l:
        if text[i] == 'ь':
            new_text += 'ъ'
        else:
            new_text += text[i]
        i += 1
    return new_text

'''
——————————————————————————————————————————————————————————————————————————————————————————┘
┌————————————————————————————┐
│ Функции для прилагательных │
└————————————————————————————┘
——————————————————————————————————————————————————————————————————————————————————————————┐
'''

def unify_ii_to_yi(text):
    cdef unicode new_text = ''
    if len(text) > 2:
        if text[-2] == 'о' and text[-1] == 'и':
            new_text = text[:-1] + 'ꙑи'
        else:
            new_text = text
    else:
        new_text = text
    return new_text


def replace_final_vowels_in_adj(text):
    cdef unicode new_text = ''
    if len(text) > 2:
        if text[-3] in 'кгх' and text[-2] == 'ꙑ' and text[-1] == 'и':
            new_text = text[:-2] + 'ии'
        else:
            new_text = text
    else:
        new_text = text
    return new_text

'''
——————————————————————————————————————————————————————————————————————————————————————————┘
┌—————┐
│ API │
└—————┘
——————————————————————————————————————————————————————————————————————————————————————————┐
'''

def pre_unify(text):
    """Унифицирует всё, кроме редуцированных."""
    if not text:
        return ''
    cdef unicode new_text
    new_text = strip_stuff(text)
    new_text = unify_various_symbols(new_text)
    new_text = unify_final_shwa(new_text)
    new_text = unify_vowels_after_set1(new_text)
    new_text = unify_iotated(new_text)
    new_text = unify_i_and_front_shwa(new_text)
    new_text = unify_r_and_l_with_shwas1(new_text)
    new_text = unify_r_and_l_with_shwas2(new_text)
    new_text = unify_r_and_l_with_yat(new_text)
    new_text = unify_ii_to_yi(new_text)
    new_text = replace_final_vowels_in_adj(new_text)
    new_text = ie(new_text)
    return new_text


def unify(text):
    """Принимает слово на древнерусском языке и переводит его в унифицированный вид.
    
    Алгоритм сделан на основе статей:
    "Автоматический морфологический анализатор древнерусского языка: лингвистические и технологические решения". Баранов, Миронов, Лапин, Мельникова, Соколова, Корепанова.
    "ВЗIAЛЪ, ВЪЗЯЛЪ, ВЬЗЯЛ: ОБРАБОТКА ОРФОГРАФИЧЕСКОЙ ВАРИАТИВНОСТИ ПРИ ЛЕКСИКО-ГРАММАТИЧЕСКОЙ АННОТАЦИИ СТАРОРУССКОГО КОРПУСА XV–XVII ВВ.*". Т. С. Г АВРИЛОВА, Т. А. ШАЛГАНОВА, О. Н. ЛЯШЕВСКАЯ.

    Алгоритм унификации:
    1) Привести к нижнему регистру, удалить лишние знаки и т.д.
    2) Привести равнозначные знаки и фонологически незначимые отличия к единой форме. Подробнее см. unify_various_symbols
    3) Привести конечный редуцированный в "ъ".
    4) Уменьшить разнообразие гласные после после шипящих. Подробнее см. unify_vowels_after_set1
    5) Дезйотировать гласные в позиции начала слова и после гласных. Подробнее см. unify_iotated
    6) Перевести "ь" после йотированных гласных и "i" в "и".
    7) Преобразовать ряд сочетаний плавных с гласными. Подробнее см. unify_r_and_l_with_shwas1, unify_r_and_l_with_shwas2 и unify_r_and_l_with_yat
    8) Сровнять молодой в молодꙑй.
    8) Сровнять типа вꙑсокꙑи и вꙑсокии во второй вариант.
    9) Сровнять ие и ье (варенье/ варение)
    10) Эмулировать падение редуцированных.
    11) Добавить принцип открытого слога.
    """
    if not text:
        return ''
    cdef unicode new_text
    new_text = pre_unify(text)
    new_text = drop_shwas(new_text)
    new_text = add_shwas(new_text)
    return new_text


def all_options(word):
    """Данная функция возвращает все возможные способы написания касательно редуцированных.
    
    1. Редуцированные упали/прояснились.
    2. Редуцированные добавились по принципу открытого слога.
    #3. Редуцированные прояснились в є/о.
    4. Редуцированные добавились, после чего упали/прояснились.
    #5. Редуцированные добавились, после чего прояснились в є/о.
    #6. Редуцированные совпали в ъ.
    
    После этого во всех случаях добавляются ъ по принципу открытого слога
    """
    cdef unicode pre_unified = pre_unify(word)

    cdef unicode word_without_shwas = drop_shwas(pre_unified)
    cdef unicode word_with_open_shwa_vowels = add_shwas(pre_unified)
    cdef unicode word_replaced_shwas = replace_shwas(pre_unified)
    cdef unicode word_with_dropped_open_shwa_vowels = drop_shwas(word_with_open_shwa_vowels)
    cdef unicode word_added_replaced = replace_shwas(word_with_open_shwa_vowels)
    
    return tuple(map(add_shwas, (word_without_shwas, word_with_open_shwa_vowels, word_with_dropped_open_shwa_vowels)))


def compare(word1, word2):
    """Данная функция сравнивает два слова тремя способами.
    
    1. Редуцированные упали/прояснились.
    2. Редуцированные добавились по принципу открытого слога.
    4. Редуцированные добавились, после чего упали/прояснились.
    """
    cdef unicode pre_unified1 = pre_unify(word1)
    cdef unicode pre_unified2 = pre_unify(word2)
    
    cdef unicode word1_without_shwas = drop_shwas(pre_unified1)
    cdef unicode word2_without_shwas = drop_shwas(pre_unified2)
    if word1_without_shwas == word2_without_shwas:
        return add_shwas(word1_without_shwas)
    
    cdef unicode word1_with_open_shwa_vowels = add_shwas(pre_unified1)
    cdef unicode word2_with_open_shwa_vowels = add_shwas(pre_unified2)
    if word1_with_open_shwa_vowels == word2_with_open_shwa_vowels:
        return word1_with_open_shwa_vowels
    
    cdef unicode word1_with_dropped_open_shwa_vowels = drop_shwas(word1_with_open_shwa_vowels)
    cdef unicode word2_with_dropped_open_shwa_vowels = drop_shwas(word2_with_open_shwa_vowels)
    if word1_with_dropped_open_shwa_vowels == word2_with_dropped_open_shwa_vowels:
        return word1_with_dropped_open_shwa_vowels


def full_comparison(word1, word2):
    """Возвращает все совпадающие варианты."""
    cdef tuple word1_vars = all_options(word1)
    cdef tuple word2_vars = all_options(word2)
    cdef list result = []
    cdef int i = 0
    cdef int l1 = len(word1_vars)
    cdef int j = 0
    cdef int l2 = len(word2_vars)
    while i < l1:
        j = 0
        while j < l2:
            if word1_vars[i] == word2_vars[j]:
                result.append(word1_vars[i])
            j += 1
        i += 1
    return result


def safe_comparison(word1, word2):
    """Возвращает вариант, совпадающий с unify(word1) или unify(word2)."""
    cdef list vares = full_comparison(word1, word2)
    cdef unicode unified = unify(word1)
    cdef unicode unified2 = unify(word2)
    for var in vares:
        if var == unified or var == unified2:
            return var


def unify_text(text):
    """Принимает текст, возвращает строку.
    
    >>> unify_text('мълъва прошла')
    'молъва пърошъла'
    """
    cdef list words = text.split()
    cdef list new_words = []
    cdef unicode word
    cdef unicode new_word
    cdef long long int i = 0
    cdef long long int l = len(words)
    while i < l:
        word = words[i]
        new_word = unify(word)
        new_words.append(new_word)
        i += 1
    return ' '.join(new_words)

def fully_unify_text(text):
    """Принимает текст, возвращает список списков со вариантами всех слов.
    
    >>> fully_unify_text('мълъва прошла')
    [['молъва', 'мълъва'], ['пърошъла']]
    """
    cdef list words = text.split()
    cdef list new_words = []
    cdef unicode word
    
    cdef tuple new_word
    cdef list used
    cdef list result
    
    cdef long long int i = 0
    cdef long long int l = len(words)
    while i < l:
        word = words[i]
        new_word = all_options(word)
        used = []
        result = [x for x in new_word if x not in used and (used.append(x) or True)]
        new_words.append(result)
        i += 1
    return new_words
    
    
    
