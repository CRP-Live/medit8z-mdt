// ════════════════════════════════════════════════════════════════════
// MEDIT8Z MDT - PHASE 2 COMPLETE VERSION
// ════════════════════════════════════════════════════════════════════

var isOpen = false;
var playerData = {};
var departmentData = {};
var currentTab = 'dashboard';
var timeInterval = null;

// ════════════════════════════════════════════════════════════════════
// Core Functions
// ════════════════════════════════════════════════════════════════════

// Get resource name helper
function getResourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'medit8z-mdt';
}

// Close MDT Function
function closeMDT() {
    if (!isOpen) return;
    
    console.log('[MDT] Closing MDT');
    isOpen = false;
    
    // Hide the UI
    document.getElementById('mdt-container').style.display = 'none';
    
    // Stop time updater
    if (timeInterval) {
        clearInterval(timeInterval);
        timeInterval = null;
    }
    
    // Clean up dashboard if it exists
    if (typeof cleanupDashboard === 'function') {
        try {
            cleanupDashboard();
        } catch (e) {
            console.error('[MDT] Error cleaning dashboard:', e);
        }
    }
    
    // Clear search fields
    var profileSearch = document.getElementById('profile-search');
    if (profileSearch) profileSearch.value = '';
    
    var globalSearch = document.getElementById('global-search');
    if (globalSearch) globalSearch.value = '';
    
    // Tell the game to close
    fetch('https://' + getResourceName() + '/close', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
}

// Open MDT Function
function openMDT(data) {
    if (isOpen) return;
    
    console.log('[MDT] Opening MDT');
    isOpen = true;
    
    // Store data
    playerData = data.playerData || {};
    departmentData = {};
    
    if (data.config && data.config.departments && data.department) {
        departmentData = data.config.departments[data.department] || {};
    }
    
    // Update player info
    updatePlayerInfo();
    updateAvailableTabs();
    
    // Update department name
    var deptName = document.getElementById('department-name');
    if (deptName) {
        deptName.textContent = getDepartmentTitle(data.department);
    }
    
    // Show the UI
    document.getElementById('mdt-container').style.display = 'flex';
    
    // Start time updater
    startTimeUpdater();
    
    // Initialize dashboard after delay
    setTimeout(function() {
        if (typeof initializeDashboard === 'function') {
            try {
                initializeDashboard();
            } catch (e) {
                console.error('[MDT] Error initializing dashboard:', e);
            }
        }
    }, 100);
    
    // Send loaded callback
    fetch('https://' + getResourceName() + '/loaded', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
}

// ════════════════════════════════════════════════════════════════════
// UI Update Functions
// ════════════════════════════════════════════════════════════════════

function updatePlayerInfo() {
    var officerInfo = document.getElementById('officer-info');
    if (officerInfo) {
        officerInfo.textContent = (playerData.jobLabel || 'Unknown') + ' - ' + (playerData.rankLabel || 'Unknown');
    }
    
    var nameDisplay = document.getElementById('officer-name-display');
    if (nameDisplay) nameDisplay.textContent = playerData.name || 'Unknown';
    
    var callsign = document.getElementById('officer-callsign');
    if (callsign) callsign.textContent = playerData.callsign || 'N/A';
    
    var rank = document.getElementById('officer-rank');
    if (rank) rank.textContent = playerData.rankLabel || 'Unknown';
}

function updateAvailableTabs() {
    var tabs = document.querySelectorAll('.nav-tab');
    for (var i = 0; i < tabs.length; i++) {
        var tab = tabs[i];
        var feature = tab.dataset.tab;
        if (departmentData.features && departmentData.features[feature] === false) {
            tab.style.display = 'none';
        } else {
            tab.style.display = 'block';
        }
    }
}

function getDepartmentTitle(department) {
    var titles = {
        'Police': 'Police Mobile Data Terminal',
        'EMS': 'Emergency Medical Services Terminal',
        'DOJ': 'Department of Justice Terminal',
        'Towing': 'Towing Management System'
    };
    return titles[department] || 'Mobile Data Terminal';
}

// ════════════════════════════════════════════════════════════════════
// Tab System
// ════════════════════════════════════════════════════════════════════

function switchTab(tabName) {
    // Update nav tabs
    var allTabs = document.querySelectorAll('.nav-tab');
    for (var i = 0; i < allTabs.length; i++) {
        if (allTabs[i].dataset.tab === tabName) {
            allTabs[i].classList.add('active');
        } else {
            allTabs[i].classList.remove('active');
        }
    }
    
    // Update content
    var allContent = document.querySelectorAll('.tab-content');
    for (var i = 0; i < allContent.length; i++) {
        allContent[i].classList.remove('active');
    }
    
    var content = document.getElementById(tabName);
    if (content) {
        content.classList.add('active');
    }
    
    currentTab = tabName;
    console.log('[MDT] Switched to tab:', tabName);
    
    // Refresh dashboard if needed
    if (tabName === 'dashboard' && typeof fetchDashboardData === 'function') {
        fetchDashboardData();
    }
}

// ════════════════════════════════════════════════════════════════════
// Time Updater
// ════════════════════════════════════════════════════════════════════

function startTimeUpdater() {
    updateTime();
    if (timeInterval) clearInterval(timeInterval);
    timeInterval = setInterval(updateTime, 1000);
}

function updateTime() {
    var timeEl = document.getElementById('current-time');
    if (!timeEl) return;
    
    var now = new Date();
    var hours = now.getHours().toString();
    var minutes = now.getMinutes().toString();
    if (hours.length < 2) hours = '0' + hours;
    if (minutes.length < 2) minutes = '0' + minutes;
    timeEl.textContent = hours + ':' + minutes;
}

// ════════════════════════════════════════════════════════════════════
// Search Functions
// ════════════════════════════════════════════════════════════════════

function searchProfiles() {
    var input = document.getElementById('profile-search');
    if (!input) return;
    
    var query = input.value.trim();
    if (query.length < 2) {
        if (typeof showNotification === 'function') {
            showNotification({
                type: 'error',
                title: 'Search Error',
                message: 'Please enter at least 2 characters'
            });
        }
        return;
    }
    
    var results = document.getElementById('profile-results');
    if (results) {
        results.innerHTML = '<div class="loading"></div> Searching...';
    }
    
    fetch('https://' + getResourceName() + '/searchProfiles', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({query: query})
    }).then(function(resp) {
        return resp.json();
    }).then(function(data) {
        displayProfileResults(data);
    }).catch(function(err) {
        console.error('[MDT] Search error:', err);
    });
}

function displayProfileResults(results) {
    var container = document.getElementById('profile-results');
    if (!container) return;
    
    if (!results || results.length === 0) {
        container.innerHTML = '<p class="no-results">No profiles found</p>';
        return;
    }
    
    var html = '<div class="profile-results-grid">';
    for (var i = 0; i < results.length; i++) {
        var profile = results[i];
        html += `
            <div class="profile-result-card" onclick="openProfileFromSearch('${profile.citizenid}')">
                <div class="profile-header">
                    <span class="profile-name">${profile.fullname}</span>
                    <span class="profile-id">ID: ${profile.citizenid}</span>
                </div>
                <div class="profile-details">
                    <p>Phone: ${profile.phone}</p>
                    <p>DOB: ${profile.dob}</p>
                    <p>Job: ${profile.job}</p>
                </div>
                <div class="profile-footer">
                    <span class="click-to-open">Click to open full profile</span>
                </div>
            </div>
        `;
    }
    html += '</div>';
    container.innerHTML = html;
}

// Add this function to handle profile opening
window.openProfileFromSearch = function(citizenId) {
    console.log('[MDT] Opening profile:', citizenId);
    
    // For now, show the info in a modal or alert
    // This will be expanded in Phase 3
    if (typeof showNotification === 'function') {
        showNotification({
            type: 'info',
            title: 'Profile: ' + citizenId,
            message: 'Full profile view coming in Phase 3. CitizenID: ' + citizenId
        });
    }
    
    // You can also switch to profiles tab and load that specific profile
    switchTab('profiles');
    
    // Store the selected citizen for later use
    window.selectedCitizen = citizenId;
};

// ════════════════════════════════════════════════════════════════════
// Quick Actions
// ════════════════════════════════════════════════════════════════════

function handleQuickAction(action) {
    console.log('[MDT] Quick action:', action);
    
    switch(action) {
        case 'new-report':
            switchTab('reports');
            break;
        case 'search-profile':
            switchTab('profiles');
            setTimeout(function() {
                var input = document.getElementById('profile-search');
                if (input) input.focus();
            }, 100);
            break;
        case 'create-bolo':
            switchTab('bolos');
            break;
        case 'view-roster':
            switchTab('roster');
            break;
    }
}

// ════════════════════════════════════════════════════════════════════
// Dashboard Stats Update
// ════════════════════════════════════════════════════════════════════

function updateDashboardStats(stats) {
    if (!stats) return;
    
    // Update counters
    if (stats.activeUnits !== undefined) {
        var el = document.getElementById('active-units');
        if (el) el.textContent = stats.activeUnits;
    }
    
    if (stats.recentCalls !== undefined) {
        var el = document.getElementById('recent-calls');
        if (el) el.textContent = stats.recentCalls;
    }
    
    if (stats.activeWarrants !== undefined) {
        var el = document.getElementById('active-warrants');
        if (el) el.textContent = stats.activeWarrants;
    }
    
    // Update statistics
    if (stats.statistics) {
        if (stats.statistics.totalArrests !== undefined) {
            var el = document.getElementById('stat-arrests-today');
            if (el) el.textContent = stats.statistics.totalArrests;
        }
        
        if (stats.statistics.totalCitations !== undefined) {
            var el = document.getElementById('stat-citations-today');
            if (el) el.textContent = stats.statistics.totalCitations;
        }
        
        if (stats.statistics.totalReports !== undefined) {
            var el = document.getElementById('stat-reports-today');
            if (el) el.textContent = stats.statistics.totalReports;
        }
    }
}

// ════════════════════════════════════════════════════════════════════
// Global Functions for onclick handlers
// ════════════════════════════════════════════════════════════════════

window.closeMDT = closeMDT;

window.activatePanicButton = function() {
    if (!confirm('Activate PANIC BUTTON? This will alert all units!')) {
        return;
    }
    
    var btn = document.querySelector('.panic-button');
    if (btn) {
        btn.style.background = '#7f1d1d';
        btn.textContent = 'PANIC ACTIVATED';
        setTimeout(function() {
            btn.style.background = '#dc2626';
            btn.textContent = 'PANIC';
        }, 3000);
    }
    
    // Flash effect first
    var flash = document.createElement('div');
    flash.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(220,38,38,0.3);z-index:9999;pointer-events:none;animation:flashPulse 0.5s ease-out';
    document.body.appendChild(flash);
    setTimeout(function() {
        flash.remove();
    }, 500);
    
    // Send panic to server using NUI callback
    fetch('https://' + getResourceName() + '/panicButton', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    }).then(function(response) {
        return response.json();
    }).then(function(data) {
        console.log('[MDT] Panic button response:', data);
    }).catch(function(error) {
        console.error('[MDT] Panic button error:', error);
    });
};

window.refreshDashboard = function() {
    if (typeof fetchDashboardData === 'function') {
        fetchDashboardData();
    }
};

window.globalSearch = function() {
    if (typeof performGlobalSearch === 'function') {
        performGlobalSearch();
    }
};

// ════════════════════════════════════════════════════════════════════
// Event Listeners
// ════════════════════════════════════════════════════════════════════

// Listen for messages from the game
window.addEventListener('message', function(event) {
    var data = event.data;
    
    switch(data.action) {
        case 'open':
            openMDT(data);
            break;
        case 'close':
            closeMDT();
            break;
        case 'updateStats':
            updateDashboardStats(data.stats);
            break;
        case 'updateDashboard':
            if (data.data) {
                updateDashboardStats(data.data);
            }
            break;
    }
});

// ESC key to close
document.addEventListener('keyup', function(event) {
    if (event.key === 'Escape' && isOpen) {
        closeMDT();
    }
});

// DOM Ready
document.addEventListener('DOMContentLoaded', function() {
    console.log('[MDT] DOM loaded');
    
    // Tab buttons
    var tabs = document.querySelectorAll('.nav-tab');
    for (var i = 0; i < tabs.length; i++) {
        tabs[i].addEventListener('click', function() {
            switchTab(this.dataset.tab);
        });
    }
    
    // Search button
    var searchBtn = document.getElementById('btn-search-profiles');
    if (searchBtn) {
        searchBtn.addEventListener('click', searchProfiles);
    }
    
    // Search input Enter key
    var searchInput = document.getElementById('profile-search');
    if (searchInput) {
        searchInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                searchProfiles();
            }
        });
    }
    
    // Quick action buttons
    var actionBtns = document.querySelectorAll('.action-btn');
    for (var i = 0; i < actionBtns.length; i++) {
        actionBtns[i].addEventListener('click', function() {
            var action = this.dataset.action;
            if (action) {
                handleQuickAction(action);
            }
        });
    }
    
    // Add animation styles
    if (!document.querySelector('#mdt-animations')) {
        var style = document.createElement('style');
        style.id = 'mdt-animations';
        style.textContent = '@keyframes flashPulse { 0% { opacity: 0; } 50% { opacity: 1; } 100% { opacity: 0; } }';
        document.head.appendChild(style);
    }
});

console.log('[MDT] Phase 2 UI loaded successfully');