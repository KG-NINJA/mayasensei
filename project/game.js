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
        // Ignore errors if audio files are missing
        console.log(`Sound file ${name}.wav not found or could not be played.`);
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
        enterRuinsBtn.classList.remove('hidden');
    }
}

function updateUI() {
    currentCoinsEl.textContent = gameState.coins;

    // Update inventory slots
    for (let i = 0; i < gameState.maxCoins; i++) {
        if (i < gameState.coins) {
            inventorySlots[i].textContent = '🪙';
        } else {
            inventorySlots[i].textContent = '';
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
        showMessage("入口の仕掛けは既に解かれている。");
    } else {
        showPuzzle();
    }
});

document.querySelectorAll('.close-modal-btn').forEach(btn => {
    btn.addEventListener('click', closeModal);
});

enterRuinsBtn.addEventListener('click', () => {
    playSound('success');
    alert("おめでとう！あなたはカラコルの深淵へと足を踏み入れた...");
    location.reload(); // Reset game for demo
});

// --- Puzzle Logic ---

function resetPuzzle() {
    gameState.puzzleOrder = [null, null, null, null];
    puzzleSlots.forEach(slot => {
        slot.textContent = '';
        slot.classList.remove('filled');
    });
    // Restore all pieces to the tray
    const tray = document.getElementById('puzzle-pieces');
    puzzlePieces.forEach(piece => {
        tray.appendChild(piece);
        piece.classList.remove('hidden');
    });
}

// Simple click-to-move logic for puzzle pieces
puzzlePieces.forEach(piece => {
    piece.addEventListener('click', () => {
        playSound('click');
        // Find first empty slot
        const emptySlotIndex = gameState.puzzleOrder.findIndex(item => item === null);
        if (emptySlotIndex !== -1) {
            const symbol = piece.getAttribute('data-type');
            gameState.puzzleOrder[emptySlotIndex] = symbol;

            const slot = puzzleSlots[emptySlotIndex];
            slot.textContent = piece.textContent;
            piece.classList.add('hidden'); // Hide from tray
        }
    });
});

puzzleSlots.forEach((slot, index) => {
    slot.addEventListener('click', () => {
        if (gameState.puzzleOrder[index]) {
            playSound('click');
            const symbol = gameState.puzzleOrder[index];
            gameState.puzzleOrder[index] = null;

            // Show the piece back in tray
            const piece = Array.from(puzzlePieces).find(p => p.getAttribute('data-type') === symbol);
            if (piece) piece.classList.remove('hidden');

            slot.textContent = '';
        }
    });
});

checkPuzzleBtn.addEventListener('click', () => {
    const isCorrect = gameState.puzzleOrder.every((val, index) => val === gameState.correctOrder[index]);

    if (isCorrect) {
        playSound('success');
        alert("仕掛けが動いた！コインを手に入れた。");
        addCoin('puzzle');
        closeModal();
    } else {
        alert("何も起こらない... 順番が違うようだ。");
    }
});

// --- Initialization ---
window.addEventListener('load', () => {
    updateUI();
});
