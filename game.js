/**
 * Maya Mystery - Caracol
 * Game Logic
 */

const gameState = {
    coins: 0,
    maxCoins: 3,
    hasCoin: {
        left: false,
        center: false,
        puzzle: false
    },
    puzzleOrder: [null, null, null, null],
    correctOrder: ['太陽', '月', '星', '蛇']
};

const SYMBOL_MAP = {
    '太陽': '☀️',
    '月': '🌙',
    '星': '⭐',
    '蛇': '🐍'
};

// --- DOM Elements ---
const currentCoinsEl = document.getElementById('current-coins');
const inventorySlots = [
    document.getElementById('slot-0'),
    document.getElementById('slot-1'),
    document.getElementById('slot-2')
];
const enterRuinsBtn = document.getElementById('enter-ruins-btn');

const modalOverlay = document.getElementById('modal-overlay');
const modalMessage = document.getElementById('modal-message');
const messageText = document.getElementById('message-text');
const modalPuzzle = document.getElementById('modal-puzzle');

const puzzleSlots = document.querySelectorAll('.puzzle-slot');
const puzzlePieces = document.querySelectorAll('.piece');
const checkPuzzleBtn = document.getElementById('check-puzzle-btn');

// --- Audio Handling ---
function playSound(name) {
    const audio = new Audio(`assets/${name}.wav`);
    audio.play().catch(() => {
        // Ignore missing audio files
    });
}

// --- Game Logic ---

function addCoin(source) {
    if (gameState.hasCoin[source]) return;

    gameState.hasCoin[source] = true;
    gameState.coins++;
    updateUI();
    playSound('success');

    if (gameState.coins >= gameState.maxCoins) {
        setTimeout(() => {
            enterRuinsBtn.classList.remove('hidden');
            playSound('success');
        }, 500);
    }
}

function updateUI() {
    currentCoinsEl.textContent = gameState.coins;

    // Update inventory slots
    for (let i = 0; i < gameState.maxCoins; i++) {
        if (i < gameState.coins) {
            inventorySlots[i].textContent = '🪙';
            inventorySlots[i].classList.add('filled');
        } else {
            inventorySlots[i].textContent = '';
            inventorySlots[i].classList.remove('filled');
        }
    }
}

function showMessage(text) {
    messageText.textContent = text;
    modalOverlay.classList.remove('hidden');
    modalMessage.classList.remove('hidden');
    modalPuzzle.classList.add('hidden');
}

function showPuzzle() {
    modalOverlay.classList.remove('hidden');
    modalPuzzle.classList.remove('hidden');
    modalMessage.classList.add('hidden');
    resetPuzzle();
}

function closeModal() {
    modalOverlay.classList.add('hidden');
    modalMessage.classList.add('hidden');
    modalPuzzle.classList.add('hidden');
}

// --- Hotspot Listeners ---

document.getElementById('hotspot-left').addEventListener('click', () => {
    playSound('click');
    showMessage("「石の模様は空を示している…」");
    addCoin('left');
});

document.getElementById('hotspot-center').addEventListener('click', () => {
    playSound('click');
    showMessage("「太陽、月、星の順番が重要だ」");
    addCoin('center');
});

document.getElementById('hotspot-right').addEventListener('click', () => {
    playSound('click');
    if (gameState.hasCoin.puzzle) {
        showMessage("入口の封印は既に解かれている。");
    } else {
        showPuzzle();
    }
});

document.querySelectorAll('.close-modal-btn').forEach(btn => {
    btn.addEventListener('click', closeModal);
});

document.getElementById('hotspot-relic').addEventListener('click', () => {
    playSound('click');
    showMessage("古代の聖遺物を見つけた！カラコルの真実が今、明かされる...");
    setTimeout(() => {
        alert("GAME CLEAR! プレイありがとうございました。");
    }, 1500);
});

enterRuinsBtn.addEventListener('click', () => {
    playSound('success');
    transitionToInterior();
});

function transitionToInterior() {
    // Hide all hotspots
    document.querySelectorAll('.hotspot').forEach(h => h.classList.add('hidden'));

    // Show interior hotspot
    document.getElementById('hotspot-relic').classList.remove('hidden');

    // Change background to interior
    const world = document.getElementById('game-world');
    world.style.backgroundImage = "url('assets/caracol_interior.png')";
    world.style.backgroundSize = "1774px 887px";
    world.style.width = "1774px";
    world.style.height = "887px";

    // Update viewport height to accommodate taller image
    const viewport = document.getElementById('viewport');
    viewport.style.height = "887px";

    // Hide enter button
    enterRuinsBtn.classList.add('hidden');

    // Show success message
    setTimeout(() => {
        showMessage("あなたはカラコルの深淵に到達した。ここにはさらなる謎が眠っている... (To Be Continued)");
    }, 1000);
}

// --- Puzzle Logic ---

function resetPuzzle() {
    gameState.puzzleOrder = [null, null, null, null];
    puzzleSlots.forEach(slot => {
        slot.textContent = '';
        slot.classList.remove('filled');
    });
    // Restore pieces
    puzzlePieces.forEach(piece => {
        piece.classList.remove('hidden');
    });
}

puzzlePieces.forEach(piece => {
    piece.addEventListener('click', () => {
        playSound('click');
        const emptySlotIndex = gameState.puzzleOrder.findIndex(item => item === null);
        if (emptySlotIndex !== -1) {
            const type = piece.getAttribute('data-type');
            gameState.puzzleOrder[emptySlotIndex] = type;

            const slot = puzzleSlots[emptySlotIndex];
            slot.textContent = SYMBOL_MAP[type];
            slot.classList.add('filled');
            piece.classList.add('hidden');
        }
    });
});

puzzleSlots.forEach((slot, index) => {
    slot.addEventListener('click', () => {
        if (gameState.puzzleOrder[index]) {
            playSound('click');
            const type = gameState.puzzleOrder[index];
            gameState.puzzleOrder[index] = null;

            const piece = Array.from(puzzlePieces).find(p => p.getAttribute('data-type') === type);
            if (piece) piece.classList.remove('hidden');

            slot.textContent = '';
            slot.classList.remove('filled');
        }
    });
});

checkPuzzleBtn.addEventListener('click', () => {
    const isCorrect = gameState.puzzleOrder.every((val, index) => val === gameState.correctOrder[index]);

    if (isCorrect) {
        playSound('success');
        alert("仕掛けが作動した！コインが手に入った。");
        addCoin('puzzle');
        closeModal();
    } else {
        playSound('click');
        alert("何も起こらない... 順番が違うようだ。");
    }
});

// --- Initialization ---
window.addEventListener('load', () => {
    updateUI();
});
