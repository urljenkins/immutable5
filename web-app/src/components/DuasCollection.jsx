import { useState } from 'react'

const duas = [
  {
    id: 1,
    category: 'Morning',
    arabic: 'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ',
    transliteration: 'Allāhumma bika aṣbaḥnā wa bika amsaynā wa bika naḥyā wa bika namūtu wa ilayka n-nushūr',
    translation: 'O Allah, by You we enter the morning and by You we enter the evening, by You we live and by You we die, and unto You is the resurrection.',
  },
  {
    id: 2,
    category: 'Evening',
    arabic: 'اللَّهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ',
    transliteration: 'Allāhumma bika amsaynā wa bika aṣbaḥnā wa bika naḥyā wa bika namūtu wa ilayka l-maṣīr',
    translation: 'O Allah, by You we enter the evening and by You we enter the morning, by You we live and by You we die, and unto You is the return.',
  },
  {
    id: 3,
    category: 'Before Eating',
    arabic: 'بِسْمِ اللهِ',
    transliteration: 'Bismillāh',
    translation: 'In the name of Allah',
  },
  {
    id: 4,
    category: 'After Eating',
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
    transliteration: 'Alḥamdu lillāhi lladhī aṭʿamanā wa saqānā wa jaʿalanā muslimīn',
    translation: 'Praise be to Allah who has fed us and given us drink and made us Muslims',
  },
  {
    id: 5,
    category: 'Travel',
    arabic: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ',
    transliteration: 'Subḥāna lladhī sakhkhara lanā hādhā wa mā kunnā lahu muqrinīn',
    translation: 'Glory to Him who has subjected this to us, and we could never have it by our efforts.',
  },
  {
    id: 6,
    category: 'Difficulty',
    arabic: 'حَسْبُنَا اللهُ وَنِعْمَ الْوَكِيلُ',
    transliteration: 'Ḥasbunā llāhu wa niʿma l-wakīl',
    translation: 'Allah is sufficient for us and He is the best disposer of affairs',
  },
  {
    id: 7,
    category: 'Gratitude',
    arabic: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    transliteration: 'Alḥamdu lillāhi rabbi l-ʿālamīn',
    translation: 'Praise be to Allah Lord of the worlds',
  },
  {
    id: 8,
    category: 'Protection',
    arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    transliteration: 'Aʿūdhu bi-kalimāti llāhi t-tāmmāti min sharri mā khalaqa',
    translation: 'I seek refuge in the perfect words of Allah from the evil of what He has created',
  },
]

const DuasCollection = () => {
  const [selectedCategory, setSelectedCategory] = useState('All')
  const [bookmarked, setBookmarked] = useState(new Set())

  const categories = ['All', ...new Set(duas.map(d => d.category))]

  const filteredDuas = selectedCategory === 'All'
    ? duas
    : duas.filter(d => d.category === selectedCategory)

  const toggleBookmark = (id) => {
    setBookmarked(prev => {
      const newSet = new Set(prev)
      if (newSet.has(id)) {
        newSet.delete(id)
      } else {
        newSet.add(id)
      }
      return newSet
    })
  }

  const copyToClipboard = (dua) => {
    const text = `${dua.arabic}\n\n${dua.transliteration}\n\n${dua.translation}`
    navigator.clipboard.writeText(text)
      .then(() => alert('Dua copied to clipboard!'))
      .catch(err => console.error('Failed to copy:', err))
  }

  const getCategoryColor = (category) => {
    const colors = {
      'Morning': '#FF9800',
      'Evening': '#673AB7',
      'Before Eating': '#4CAF50',
      'After Eating': '#4CAF50',
      'Travel': '#2196F3',
      'Difficulty': '#F44336',
      'Gratitude': '#9C27B0',
      'Protection': '#795548',
    }
    return colors[category] || '#757575'
  }

  return (
    <div className="duas-container">
      <h2>Daily Duas</h2>

      {/* Category Filter */}
      <div className="category-filter">
        {categories.map(cat => (
          <button
            key={cat}
            className={`category-chip ${selectedCategory === cat ? 'active' : ''}`}
            onClick={() => setSelectedCategory(cat)}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Duas List */}
      <div className="duas-list">
        {filteredDuas.map(dua => (
          <div key={dua.id} className="dua-card">
            <div className="dua-header">
              <span
                className="category-badge"
                style={{ backgroundColor: getCategoryColor(dua.category) }}
              >
                {dua.category}
              </span>
              <button
                className="bookmark-btn"
                onClick={() => toggleBookmark(dua.id)}
              >
                {bookmarked.has(dua.id) ? '★' : '☆'}
              </button>
            </div>

            <div className="dua-arabic">
              {dua.arabic}
            </div>

            <div className="dua-transliteration">
              {dua.transliteration}
            </div>

            <div className="dua-translation">
              {dua.translation}
            </div>

            <button
              className="copy-btn"
              onClick={() => copyToClipboard(dua)}
            >
              📋 Copy
            </button>
          </div>
        ))}
      </div>

      {filteredDuas.length === 0 && (
        <div className="empty-state">
          <p>No duas found in this category</p>
        </div>
      )}
    </div>
  )
}

export default DuasCollection
