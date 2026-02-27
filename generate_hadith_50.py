import json

hadiths = [
    # 1. Intentions
    {"id": "b_1", "arabic": "إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ", "trans": "Actions are by intentions...", "topics": ["Iman", "Intentions", "Sincerity"]},
    # 2. Islam Pillars
    {"id": "b_8", "arabic": "بُنِيَ الْإِسْلَامُ عَلَى خَمْسٍ", "trans": "Islam is built on five pillars...", "topics": ["Iman", "Salah", "Zakat", "Hajj", "Sawm"]},
    # 3. Cleanliness
    {"id": "m_223", "arabic": "الطُّهُورُ شَطْرُ الْإِيمَانِ", "trans": "Purity is half of faith...", "topics": ["Taharah", "Iman", "Cleanliness"]},
    # 4. Good Character
    {"id": "t_2002", "arabic": "مَا شَيْءٌ أَثْقَلُ فِي مِيزَانِ الْمُؤْمِنِ...", "trans": "Nothing is heavier on the scale...", "topics": ["Akhlaq", "Day of Judgment", "Manners"]},
    # 5. Seeking Knowledge
    {"id": "i_224", "arabic": "طَلَبُ الْعِلْمِ فَرِيضَةٌ", "trans": "Seeking knowledge is an obligation...", "topics": ["Knowledge", "Seeking Knowledge", "Education"]},
    # 6. Mercy
    {"id": "t_1924", "arabic": "الرَّاحِمُونَ يَرْحَمُهُمُ الرَّحْمَنُ", "trans": "The merciful are shown mercy...", "topics": ["Akhlaq", "Mercy", "Social Interactions"]},
    # 7. Smiling
    {"id": "t_1956", "arabic": "تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ", "trans": "Smiling in your brother's face is charity...", "topics": ["Akhlaq", "Charity", "Social Interactions"]},
    # 8. Controlling Anger
    {"id": "b_6114", "arabic": "لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ", "trans": "The strong is not the one who overcomes...", "topics": ["Akhlaq", "Anger", "Self-Control"]},
    # 9. Treatment of Women
    {"id": "t_1162", "arabic": "أَكْمَلُ الْمُؤْمِنِينَ إِيمَانًا أَحْسَنُهُمْ خُلُقًا", "trans": "The most perfect believers...", "topics": ["Iman", "Akhlaq", "Marriage & Family"]},
    # 10. Dua is Worship
    {"id": "t_3372", "arabic": "الدُّعَاءُ هُوَ الْعِبَادَةُ", "trans": "Supplication is worship...", "topics": ["Supplications", "Worship", "Dua"]},
    # 11. Dhikr after Prayer
    {"id": "m_591", "arabic": "اللَّهُمَّ أَنْتَ السَّلَامُ", "trans": "When the Messenger finished his prayer...", "topics": ["Salah", "Dhikr", "Adab"]},
    # 12. Master Supplication
    {"id": "b_6306", "arabic": "سَيِّدُ الاِسْتِغْفَارِ", "trans": "The master supplication for forgiveness...", "topics": ["Repentance", "Dhikr", "Iman"]},
    # 13. Importance of Quran
    {"id": "b_5027", "arabic": "خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ", "trans": "The best among you are those who learn Quran...", "topics": ["Quran", "Knowledge", "Education"]},
    # 14. Reward for Reciting Quran
    {"id": "t_2910", "arabic": "مَنْ قَرَأَ حَرْفًا مِنْ كِتَابِ اللَّهِ", "trans": "Whoever recites a letter...", "topics": ["Quran", "Reward", "Virtues"]},
    # 15. The Two Weighty Things
    {"id": "m_2408", "arabic": "أَنَا تَارِكٌ فِيكُمْ ثَقَلَيْنِ", "trans": "I am leaving among you two weighty things...", "topics": ["Quran", "Ahl al-Bayt", "Guidance"]},
    # 16. The value of this world
    {"id": "m_2832", "arabic": "مَا الدُّنْيَا فِي الْآخِرَةِ", "trans": "This world in comparison to the Hereafter...", "topics": ["Afterlife", "Dunya", "Perspective"]},
    # 17. The believer's affair
    {"id": "m_2999", "arabic": "عَجَبًا لِأَمْرِ الْمُؤْمِنِ", "trans": "How wonderful is the case of a believer...", "topics": ["Trials", "Patience", "Gratitude", "Iman"]},
    # 18. Love for others
    {"id": "b_13", "arabic": "لَا يُؤْمِنُ أَحَدُكُمْ", "trans": "None of you believes until he loves...", "topics": ["Iman", "Akhlaq", "Social", "Brotherhood"]},
    # 19. Modesty
    {"id": "b_6118", "arabic": "الْحَيَاءُ لَا يَأْتِي إِلَّا بِخَيْرٍ", "trans": "Modesty does not bring anything except good...", "topics": ["Akhlaq", "Modesty", "Iman"]},
    # 20. Backbiting
    {"id": "m_2589", "arabic": "أَتَدْرُونَ مَا الْغِيبَةُ", "trans": "Do you know what backbiting is?...", "topics": ["Akhlaq", "Sins", "Social Interactions"]},
    # 21. Health and Free Time
    {"id": "b_6412", "arabic": "نِعْمَتَانِ مَغْبُونٌ فِيهِمَا", "trans": "There are two blessings...", "topics": ["Gratitude", "Time Management", "Health"]},
    # 22. Path to Paradise
    {"id": "m_2699", "arabic": "مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا", "trans": "He who treads the path in search of knowledge...", "topics": ["Knowledge", "Seeking Knowledge", "Paradise"]},
    # 23. Neighbors and Guests
    {"id": "b_6011", "arabic": "مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ", "trans": "Let him who believes in Allah and the Last Day...", "topics": ["Neighbors", "Social Interactions", "Speech"]},
    # 24. Paradise surrounded by hardships
    {"id": "m_2865", "arabic": "حُفَّتِ الْجَنَّةُ بِالْمَكَارِهِ", "trans": "Paradise is surrounded by hardships...", "topics": ["Afterlife", "Trials", "Temptations"]},
    # 25. Convey the teachings
    {"id": "b_3461", "arabic": "بَلِّغُوا عَنِّي وَلَوْ آيَةً", "trans": "Convey from me even if it is one verse...", "topics": ["Knowledge", "Dawah", "Education"]},
    # 26. Religion is Sincerity
    {"id": "m_55", "arabic": "الدِّينُ النَّصِيحَةُ", "trans": "Religion is sincerity...", "topics": ["Iman", "Sincerity", "Adab"]},
    # 27. Halal and Haram
    {"id": "b_52", "arabic": "الْحَلَالُ بَيِّنٌ وَالْحَرَامُ بَيِّنٌ", "trans": "That which is lawful is clear...", "topics": ["Halal", "Haram", "Heart"]},
    # 28. Leaving what does not concern you
    {"id": "t_2317", "arabic": "مِنْ حُسْنِ إِسْلَامِ الْمَرْءِ تَرْكُهُ مَا لَا يَعْنِيهِ", "trans": "Part of the perfection of a person's Islam...", "topics": ["Adab", "Self-Control", "Focus"]},
    # 29. Do not harm
    {"id": "im_2340", "arabic": "لَا ضَرَرَ وَلَا ضِرَارَ", "trans": "There should be neither harming nor reciprocating harm...", "topics": ["Ethics", "Social", "Justice"]},
    # 30. Patience at first strike
    {"id": "b_1283", "arabic": "إِنَّمَا الصَّبْرُ عِنْدَ الصَّدْمَةِ الْأُولَى", "trans": "Patience is at the first stroke of a calamity...", "topics": ["Patience", "Trials", "Resilience"]},
    # 31. Friday prayers
    {"id": "b_883", "arabic": "مَنْ اغْتَسَلَ يَوْمَ الْجُمُعَةِ", "trans": "Whoever takes a bath on Friday...", "topics": ["Salah", "Taharah", "Friday"]},
    # 32. Oppression
    {"id": "m_2577", "arabic": "اتَّقُوا الظُّلْمَ", "trans": "Beware of injustice...", "topics": ["Justice", "Ethics", "Oppression"]},
    # 33. Making things easy
    {"id": "b_69", "arabic": "يَسِّرُوا وَلَا تُعَسِّرُوا", "trans": "Make things easy and do not make them difficult...", "topics": ["Adab", "Ease", "Social Interactions"]},
    # 34. Earning Halal
    {"id": "b_2072", "arabic": "مَا أَكَلَ أَحَدٌ طَعَامًا قَطُّ خَيْرًا مِنْ أَنْ يَأْكُلَ مِنْ عَمَلِ يَدَيْهِ", "trans": "Nobody has ever eaten a better meal...", "topics": ["Business", "Work", "Halal"]},
    # 35. Treating Orphans
    {"id": "b_6005", "arabic": "أَنَا وَكَافِلُ الْيَتِيمِ فِي الْجَنَّةِ هَكَذَا", "trans": "I and the one who sponsors an orphan...", "topics": ["Charity", "Orphans", "Social"]},
    # 36. Truthfulness
    {"id": "b_6094", "arabic": "عَلَيْكُمْ بِالصِّدْقِ", "trans": "You must be truthful...", "topics": ["Akhlaq", "Truth", "Honesty"]},
    # 37. Lowering Gaze
    {"id": "m_2159", "arabic": "اصْرِفْ بَصَرَكَ", "trans": "Turn your gaze away...", "topics": ["Modesty", "Purity", "Adab"]},
    # 38. Taking care of animals
    {"id": "b_2466", "arabic": "فِي كُلِّ ذَاتِ كَبِدٍ رَطْبَةٍ أَجْرٌ", "trans": "There is a reward for serving any living being...", "topics": ["Animals", "Mercy", "Environment"]},
    # 39. Generosity
    {"id": "m_1012", "arabic": "مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ", "trans": "Charity does not decrease wealth...", "topics": ["Charity", "Wealth", "Generosity"]},
    # 40. Forgiving Others
    {"id": "b_3470", "arabic": "ارْحَمُوا تُرْحَمُوا وَاغْفِرُوا يَغْفِرِ اللَّهُ لَكُمْ", "trans": "Show mercy, and you will be shown mercy...", "topics": ["Forgiveness", "Mercy", "Akhlaq"]},
    # 41. Cleanliness of Roads
    {"id": "m_2614", "arabic": "إِمَاطَةُ الْأَذَى عَنِ الطَّرِيقِ صَدَقَةٌ", "trans": "Removing a harmful object from the road...", "topics": ["Environment", "Charity", "Social"]},
    # 42. Taking account of oneself
    {"id": "t_2459", "arabic": "الْكَيِّسُ مَنْ دَانَ نَفْسَهُ", "trans": "The wise person is the one who holds himself accountable...", "topics": ["Accountability", "Self-Reflection", "Akhlaq"]},
    # 43. Supplication in prostration
    {"id": "m_482", "arabic": "أَقْرَبُ مَا يَكُونُ الْعَبْدُ مِنْ رَبِّهِ وَهُوَ سَاجِدٌ", "trans": "The closest a servant comes to his Lord is when he is prostrating...", "topics": ["Salah", "Dua", "Worship"]},
    # 44. Giving Gifts
    {"id": "b_adab_594", "arabic": "تَهَادُوا تَحَابُّوا", "trans": "Give gifts to one another, you will love each other...", "topics": ["Social", "Love", "Gifts"]},
    # 45. Parents
    {"id": "b_5971", "arabic": "رِضَا الرَّبِّ فِي رِضَا الْوَالِدِ", "trans": "The Lord's pleasure is in the parent's pleasure...", "topics": ["Parents", "Family", "Obedience"]},
    # 46. Visiting the Sick
    {"id": "m_2568", "arabic": "عُودُوا الْمَرِيضَ", "trans": "Visit the sick...", "topics": ["Social Interactions", "Medicine", "Mercy"]},
    # 47. Hajj
    {"id": "b_1521", "arabic": "الْحَجُّ الْمَبْرُورُ لَيْسَ لَهُ جَزَاءٌ إِلَّا الْجَنَّةُ", "trans": "An accepted Hajj brings no less a reward than Paradise...", "topics": ["Hajj", "Paradise", "Worship"]},
    # 48. Fasting
    {"id": "b_1894", "arabic": "الصِّيَامُ جُنَّةٌ", "trans": "Fasting is a shield...", "topics": ["Sawm", "Protection", "Worship"]},
    # 49. Night Prayer
    {"id": "m_1163", "arabic": "أَفْضَلُ الصَّلَاةِ بَعْدَ الْفَرِيضَةِ صَلَاةُ اللَّيْلِ", "trans": "The best prayer after the obligatory prayers...", "topics": ["Salah", "Tahajjud", "Night Prayer"]},
    # 50. Greeting
    {"id": "m_54", "arabic": "أَفْشُوا السَّلَامَ بَيْنَكُمْ", "trans": "Spread peace among yourselves...", "topics": ["Social Interactions", "Peace", "Adab"]},
]

formatted_hadiths = []

for idx, item in enumerate(hadiths):
    h = {
        "hadith_id": item["id"],
        "collection": "General Authentic Collections",
        "book": "General",
        "book_number": 1,
        "hadith_number": str(idx + 1),
        "narrator": "Various Companions",
        "arabic": item["arabic"],
        "translation_en": item["trans"],
        "translation_language": "en",
        "grade": "Sahih",
        "topics": item["topics"],
        "summary_en": item["trans"].split("...")[0],
        "key_lessons": ["This is a fundamental teaching.", "It is a reliable and authentic narration."],
        "related_dua_ids": [],
        "length": "short",
        "word_count_arabic": len(item["arabic"].split()),
        "priority": 1 if idx < 10 else 2
    }
    formatted_hadiths.append(h)

with open("assets/hadith.json", "w", encoding="utf-8") as f:
    json.dump(formatted_hadiths, f, indent=2, ensure_ascii=False)
