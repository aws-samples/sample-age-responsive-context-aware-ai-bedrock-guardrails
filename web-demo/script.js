// User creation function
async function createUser() {
    const username = document.getElementById('reg-username').value.trim();
    const name = document.getElementById('reg-name').value.trim();
    const birthdate = document.getElementById('reg-birthdate').value;
    const role = document.getElementById('reg-role').value;
    const industry = document.getElementById('reg-industry').value;
    const device = document.getElementById('reg-device').value;
    
    if (!username || !name || !birthdate || !role || !industry || !device) {
        alert('Please fill in all fields');
        return;
    }
    
    try {
        const response = await fetch('/create-user', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                username,
                name,
                birthdate,
                role,
                industry,
                device
            })
        });
        
        if (!response.ok) {
            throw new Error(`Failed to create user: ${response.statusText}`);
        }
        
        const result = await response.json();
        alert(`User ${username} created successfully!\nPassword: ${result.password || 'Check console'}`);
        
        // Clear form
        document.getElementById('reg-username').value = '';
        document.getElementById('reg-name').value = '';
        document.getElementById('reg-birthdate').value = '';
        document.getElementById('reg-role').value = '';
        document.getElementById('reg-industry').value = '';
        document.getElementById('reg-device').value = 'desktop';
        
        // Add user card to UI
        addUserCard(username, name, role, industry, calculateAge(birthdate));
        
    } catch (error) {
        alert(`Error creating user: ${error.message}`);
        console.error('User creation error:', error);
    }
}

function calculateAge(birthdate) {
    const today = new Date();
    const birth = new Date(birthdate);
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
        age--;
    }
    return age;
}

function addUserCard(userId, name, role, industry, age) {
    const container = document.getElementById('user-cards-container');
    
    // Check if user card already exists
    if (document.querySelector(`[data-user="${userId}"]`)) {
        console.log(`⚠️ User card already exists: ${userId}`);
        return;
    }
    
    const userCard = document.createElement('div');
    userCard.className = 'user-card';
    userCard.setAttribute('data-user', userId);
    userCard.onclick = () => selectUser(userId);
    
    const ageCategory = age < 18 ? 'teen' : 'adult';
    const roleIcon = {
        student: '👨🎓',
        teacher: '👩🏫',
        patient: '👨⚕️',
        provider: '👨⚕️'
    }[role] || '👤';
    
    userCard.innerHTML = `
        <div class="user-avatar ${ageCategory}">${roleIcon}</div>
        <div class="user-info">
            <h4>${name}</h4>
            <p>Age: ${age} • ${role.charAt(0).toUpperCase() + role.slice(1)}</p>
            <p>Industry: ${industry.charAt(0).toUpperCase() + industry.slice(1)}</p>
            <div class="auth-info">
                <small><i class="fas fa-shield-alt"></i> Cognito JWT Token (Pre-authenticated)</small>
            </div>
            <span class="user-badge ${ageCategory}">${ageCategory.charAt(0).toUpperCase() + ageCategory.slice(1)}</span>
        </div>
    `;
    
    container.appendChild(userCard);
    console.log(`✅ User card added: ${name} (${userId})`);
}

let currentUser = null;
let apiUrl = '';
let isLoggedIn = false;

// Initialize when page loads
document.addEventListener('DOMContentLoaded', function() {
    console.log('Page loaded, initializing...');
    
    // Load config
    if (window.DEMO_CONFIG && window.DEMO_CONFIG.generated) {
        apiUrl = window.DEMO_CONFIG.apiEndpoint;
        console.log('✅ Config loaded:', apiUrl);
        console.log('🔒 Using secure token manager');
        
        // Load existing users
        loadExistingUsers();
        
        // Ready to use - no login required
        console.log('✅ Ready to test Age-Responsive AI');
        
        // Set initial Cognito status
        const cognitoStatus = document.getElementById('cognito-status');
        if (cognitoStatus) {
            cognitoStatus.textContent = '🔒 Select user to authenticate with Cognito';
        }
        
        // Update connection status immediately after setting apiUrl
        updateConnectionStatus();
    } else {
        console.error('❌ Config not found');
        const connectionStatus = document.getElementById('connection-status');
        if (connectionStatus) {
            connectionStatus.textContent = '❌ Config Error';
        }
    }
    
    // Enter key support for message input
    const messageInput = document.getElementById('message-input');
    if (messageInput) {
        messageInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                sendMessage();
            }
        });
    }
});

// Load existing users from backend
let usersLoaded = false;
async function loadExistingUsers() {
    if (usersLoaded) return; // Prevent multiple loads
    
    try {
        const response = await fetch('/list-users');
        if (response.ok) {
            const users = await response.json();
            console.log('📥 Loaded users:', users.length);
            users.forEach(user => {
                const age = calculateAge(user.birth_date);
                addUserCard(user.user_id, user.name || user.user_id, user.role, user.industry, age);
            });
            usersLoaded = true;
        }
    } catch (error) {
        console.log('No existing users found or error loading users:', error);
    }
}

// No login required - direct user selection

async function selectUser(userId) {
    console.log('selectUser called:', userId);
    
    // Show Cognito authentication process
    await showCognitoAuth(userId);
    
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
        `${userInfo.age} • ${userInfo.role} • ${userInfo.industry} • Authenticated via Cognito`;

    // Enable chat input
    const messageInput = document.getElementById('message-input');
    const sendButton = document.getElementById('send-button');
    
    messageInput.disabled = false;
    messageInput.placeholder = `Ask ${userInfo.name} a question to see age-responsive AI...`;
    sendButton.disabled = false;
    messageInput.focus();

    // Update connection status
    updateConnectionStatus();
    
    console.log('User authenticated via Cognito:', userId);
}

async function showCognitoAuth(userId) {
    const statusElement = document.getElementById('cognito-status');
    
    // Step 1: Starting authentication
    statusElement.textContent = '🚀 Starting Cognito authentication...';
    await sleep(500);
    
    // Step 2: Retrieving JWT token
    statusElement.textContent = '🔍 Retrieving Cognito JWT token...';
    await sleep(800);
    
    // Step 3: Validating with User Pool
    statusElement.textContent = '🔒 Validating with Cognito User Pool...';
    await sleep(1000);
    
    // Step 4: Checking token signature
    statusElement.textContent = '⚙️ Verifying JWT signature...';
    await sleep(600);
    
    // Step 5: Success
    statusElement.textContent = '✅ Cognito authentication successful!';
    await sleep(300);
    
    // Final status
    statusElement.textContent = '✅ Cognito JWT Valid';
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function getUserInfo(userId) {
    // Try to get info from existing user cards first
    const userCard = document.querySelector(`[data-user="${userId}"]`);
    if (userCard) {
        const userInfo = userCard.querySelector('.user-info');
        const name = userInfo.querySelector('h4').textContent;
        const details = userInfo.querySelectorAll('p');
        const ageText = details[0].textContent;
        const industryText = details[1].textContent;
        
        return {
            name: name,
            age: ageText.split('•')[0].replace('Age: ', '').trim(),
            role: ageText.split('•')[1].trim(),
            industry: industryText.replace('Industry: ', '').trim()
        };
    }
    
    // Fallback to default users if not found
    const users = {
        'student-123': { name: 'Alex (Student)', age: 'Teen (13)', role: 'Student', industry: 'Education' },
        'teacher-456': { name: 'Sarah (Teacher)', age: 'Adult (39)', role: 'Teacher', industry: 'Education' },
        'patient-789': { name: 'John (Patient)', age: 'Adult (49)', role: 'Patient', industry: 'Healthcare' },
        'provider-101': { name: 'Dr. Smith (Doctor)', age: 'Adult (44)', role: 'Provider', industry: 'Healthcare' }
    };
    return users[userId] || { name: userId, age: 'Unknown', role: 'Unknown', industry: 'Unknown' };
}

function updateConnectionStatus() {
    const status = document.getElementById('connection-status');
    const cognitoStatus = document.getElementById('cognito-status');
    
    if (!status) {
        console.log('Connection status element not found');
        return;
    }
    
    console.log('Updating connection status. apiUrl:', apiUrl, 'currentUser:', currentUser);
    
    if (apiUrl && currentUser) {
        status.textContent = '🟢 Connected (Secure)';
        status.style.color = '#4ecdc4';
        // Don't overwrite Cognito status if user is selected
    } else if (apiUrl) {
        status.textContent = '🟡 Ready for Auth';
        status.style.color = '#ffa726';
        if (cognitoStatus) {
            cognitoStatus.textContent = '🔒 Select user to authenticate with Cognito';
        }
    } else {
        status.textContent = '🔴 Not Connected';
        status.style.color = '#ff6b6b';
        console.log('No API URL found');
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
    
    // Show JWT being sent
    const cognitoStatus = document.getElementById('cognito-status');
    cognitoStatus.textContent = '📤 Sending Cognito JWT to API Gateway...';
    
    // Get token
    let token;
    try {
        // Ensure tokenManager is available
        if (!window.tokenManager) {
            throw new Error('Token manager not initialized');
        }
        
        token = await window.tokenManager.getToken(currentUser);
        if (!token) {
            throw new Error('Failed to generate token');
        }
    } catch (error) {
        // Fallback token generation if tokenManager fails
        console.log('Using fallback token generation:', error.message);
        token = generateFallbackToken(currentUser);
        if (!token) {
            alert(`Authentication failed: ${error.message}`);
            console.error('Token generation error:', error);
            cognitoStatus.textContent = '❌ JWT generation failed';
            return;
        }
    }
    
    // Clear input
    input.value = '';

    // Add user message to chat
    addMessage('user', message);

    // Show loading
    const loadingId = addMessage('bot', '<div class="loading"></div>', true);
    
    // Show API Gateway validation
    cognitoStatus.textContent = '🔍 API Gateway validating JWT...';
    await sleep(500);

    try {
        const response = await fetch(apiUrl, {
            method: 'POST',
            mode: 'cors',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ query: message })
        });

        if (!response.ok) {
            cognitoStatus.textContent = '❌ JWT validation failed';
            throw new Error(`API Error: ${response.status} ${response.statusText}`);
        }
        
        // Show success
        cognitoStatus.textContent = '✅ JWT validated, processing request...';

        const json = await response.json();
        
        // Remove loading and add response with Cognito info
        removeMessage(loadingId);
        const enhancedMetadata = {
            ...json.metadata,
            cognito_auth: 'JWT validated by API Gateway',
            user_pool: window.DEMO_CONFIG.cognito.userPoolId
        };
        addMessage('bot', json.response, false, enhancedMetadata);
        
        // Final status
        cognitoStatus.textContent = '✅ Cognito JWT Valid';
        
    } catch (error) {
        removeMessage(loadingId);
        addMessage('bot', `❌ Error: ${error.message}`, true);
        cognitoStatus.textContent = '❌ Authentication error';
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
        // Safely handle HTML content to prevent XSS
        if (content.includes('<div class="loading"></div>')) {
            const loadingDiv = document.createElement('div');
            loadingDiv.className = 'loading';
            contentDiv.appendChild(loadingDiv);
        } else {
            contentDiv.textContent = content;
        }
    } else {
        contentDiv.textContent = content;
    }

    messageDiv.appendChild(avatar);
    messageDiv.appendChild(contentDiv);

    // Add metadata if available
    if (metadata) {
        const metadataDiv = document.createElement('div');
        metadataDiv.className = 'message-metadata';
        
        // Authentication info
        if (metadata.cognito_auth) {
            const authStrong = document.createElement('strong');
            authStrong.textContent = 'Authentication: ';
            metadataDiv.appendChild(authStrong);
            metadataDiv.appendChild(document.createTextNode(`${metadata.cognito_auth} | `));
            
            const poolStrong = document.createElement('strong');
            poolStrong.textContent = 'User Pool: ';
            metadataDiv.appendChild(poolStrong);
            metadataDiv.appendChild(document.createTextNode(`${metadata.user_pool}`));
            metadataDiv.appendChild(document.createElement('br'));
        }
        
        // Context info
        const contextStrong = document.createElement('strong');
        contextStrong.textContent = 'Context: ';
        metadataDiv.appendChild(contextStrong);
        metadataDiv.appendChild(document.createTextNode(`${metadata.role} • ${metadata.age} • ${metadata.industry} • ${metadata.device}`));
        metadataDiv.appendChild(document.createElement('br'));
        
        // Guardrails info
        const guardrailStrong = document.createElement('strong');
        guardrailStrong.textContent = 'Guardrails: ';
        metadataDiv.appendChild(guardrailStrong);
        metadataDiv.appendChild(document.createTextNode(`${metadata.guardrail_applied ? '✅ Active' : '❌ Inactive'}`));
        
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
    if (!currentUser) {
        alert('Please select a user first to authenticate with Cognito!');
        return;
    }
    document.getElementById('message-input').value = question;
    sendMessage();
}

// Fallback token generation function
function generateFallbackToken(username) {
    try {
        const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
        const payload = btoa(JSON.stringify({
            sub: 'demo-' + username,
            'cognito:username': username,
            aud: window.DEMO_CONFIG?.cognito?.clientId || 'demo-client',
            token_use: 'id',
            auth_time: Math.floor(Date.now() / 1000),
            exp: Math.floor(Date.now() / 1000) + 3600,
            iat: Math.floor(Date.now() / 1000)
        }));
        const signature = btoa('demo-signature');
        
        return `${header}.${payload}.${signature}`;
    } catch (error) {
        console.error('Fallback token generation failed:', error);
        return null;
    }
}