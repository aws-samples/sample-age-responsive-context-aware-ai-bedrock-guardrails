let currentUser = null;
let apiUrl = '';
let userTokens = {};

// Initialize when page loads
document.addEventListener('DOMContentLoaded', function() {
    console.log('Page loaded, initializing...');
    
    // Load config
    if (window.DEMO_CONFIG && window.DEMO_CONFIG.generated) {
        apiUrl = window.DEMO_CONFIG.apiEndpoint;
        userTokens = window.DEMO_CONFIG.tokens;
        console.log('✅ Config loaded:', apiUrl);
        console.log('✅ Tokens loaded:', Object.keys(userTokens));
        updateConnectionStatus();
    } else {
        console.error('❌ Config not found');
        document.getElementById('connection-status').textContent = '❌ Config Error';
    }
    
    // Enter key support
    document.getElementById('message-input').addEventListener('keypress', function(e) {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });
});

function selectUser(userId) {
    console.log('selectUser called:', userId);
    
    // Update UI
    document.querySelectorAll('.user-card').forEach(card => {
        card.classList.remove('selected');
    });
    document.querySelector(`[data-user="${userId}"]`).classList.add('selected');

    currentUser = userId;
    
    // Update header
    const userInfo = getUserInfo(userId);
    document.getElementById('current-user-name').textContent = userInfo.name;
    document.getElementById('current-user-context').textContent = 
        `${userInfo.age} • ${userInfo.role} • ${userInfo.industry}`;

    // Enable chat input
    const messageInput = document.getElementById('message-input');
    const sendButton = document.getElementById('send-button');
    
    messageInput.disabled = false;
    messageInput.placeholder = `Ask ${userInfo.name} a question to see age-responsive AI...`;
    sendButton.disabled = false;
    messageInput.focus();

    // Update connection status
    updateConnectionStatus();
    
    console.log('User selected:', userId, 'Token available:', !!userTokens[userId]);
}

function getUserInfo(userId) {
    const users = {
        'student-123': { name: 'Alex (Student)', age: 'Teen (13)', role: 'Student', industry: 'Education' },
        'teacher-456': { name: 'Sarah (Teacher)', age: 'Adult (39)', role: 'Teacher', industry: 'Education' },
        'patient-789': { name: 'John (Patient)', age: 'Adult (49)', role: 'Patient', industry: 'Healthcare' },
        'provider-101': { name: 'Dr. Smith (Doctor)', age: 'Adult (44)', role: 'Provider', industry: 'Healthcare' }
    };
    return users[userId] || {};
}

function updateConnectionStatus() {
    const status = document.getElementById('connection-status');
    if (apiUrl && currentUser && userTokens[currentUser]) {
        status.textContent = '🟢 Connected';
        status.style.color = '#4ecdc4';
    } else if (apiUrl) {
        status.textContent = '🟡 API Set';
        status.style.color = '#ffa726';
    } else {
        status.textContent = '🔴 Not Connected';
        status.style.color = '#ff6b6b';
    }
}

async function sendMessage() {
    const input = document.getElementById('message-input');
    const message = input.value.trim();
    
    if (!message) {
        alert('Please enter a question!');
        return;
    }
    
    if (!currentUser) {
        alert('Please select a user first!');
        return;
    }
    
    if (!userTokens[currentUser]) {
        alert(`No authentication token available for ${currentUser}!`);
        console.error('Available tokens:', Object.keys(userTokens));
        return;
    }
    
    // Clear input
    input.value = '';

    // Add user message to chat
    addMessage('user', message);

    // Show loading
    const loadingId = addMessage('bot', '<div class="loading"></div>', true);

    try {
        const response = await fetch(apiUrl, {
            method: 'POST',
            mode: 'cors',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${userTokens[currentUser]}`
            },
            body: JSON.stringify({ query: message })
        });

        if (!response.ok) {
            throw new Error(`API Error: ${response.status} ${response.statusText}`);
        }

        const json = await response.json();
        
        // Remove loading and add response
        removeMessage(loadingId);
        addMessage('bot', json.response, false, json.metadata);
        
    } catch (error) {
        removeMessage(loadingId);
        addMessage('bot', `❌ Error: ${error.message}`, true);
    }
}

function addMessage(type, content, isHTML = false, metadata = null) {
    const messagesContainer = document.getElementById('chat-messages');
    const messageId = 'msg_' + Date.now();
    
    // Remove welcome message if it exists
    const welcome = messagesContainer.querySelector('.welcome-message');
    if (welcome) welcome.remove();

    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${type}`;
    messageDiv.id = messageId;
    
    if (metadata) {
        messageDiv.classList.add(metadata.age);
    }

    const avatar = document.createElement('div');
    avatar.className = 'message-avatar';
    avatar.textContent = type === 'user' ? '👤' : '🤖';

    const contentDiv = document.createElement('div');
    contentDiv.className = 'message-content';
    
    if (isHTML) {
        contentDiv.innerHTML = content;
    } else {
        contentDiv.textContent = content;
    }

    messageDiv.appendChild(avatar);
    messageDiv.appendChild(contentDiv);

    // Add metadata if available
    if (metadata) {
        const metadataDiv = document.createElement('div');
        metadataDiv.className = 'message-metadata';
        metadataDiv.innerHTML = `
            <strong>Context:</strong> ${metadata.role} • ${metadata.age} • ${metadata.industry} • ${metadata.device}
            <br><strong>Guardrails:</strong> ${metadata.guardrail_applied ? '✅ Active' : '❌ Inactive'}
        `;
        messageDiv.appendChild(metadataDiv);
    }

    messagesContainer.appendChild(messageDiv);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;

    return messageId;
}

function removeMessage(messageId) {
    const message = document.getElementById(messageId);
    if (message) {
        message.remove();
    }
}

function clearChat() {
    const messagesContainer = document.getElementById('chat-messages');
    messagesContainer.innerHTML = `
        <div class="welcome-message">
            <h3>🚀 Chat Cleared</h3>
            <p>Ask a question to see age-responsive AI in action!</p>
        </div>
    `;
}

function askQuestion(question) {
    document.getElementById('message-input').value = question;
    sendMessage();
}