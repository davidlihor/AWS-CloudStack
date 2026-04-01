class CloudTaskApp {
    constructor() {
        this.tasks = [];
        this.currentFilter = 'all';
        this.pendingDeleteTaskId = null;
        this.uploadingTaskId = null;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.checkAuthState();
    }

    setupEventListeners() {
        document.getElementById('show-login-btn')?.addEventListener('click', () => this.showPage('login-page'));
        document.getElementById('show-signup-btn')?.addEventListener('click', () => this.showPage('signup-page'));
        document.getElementById('switch-to-login')?.addEventListener('click', (e) => {
            e.preventDefault();
            this.showPage('login-page');
        });
        document.getElementById('switch-to-signup')?.addEventListener('click', (e) => {
            e.preventDefault();
            this.showPage('signup-page');
        });
        document.getElementById('signup-form')?.addEventListener('submit', (e) => this.handleSignup(e));
        document.getElementById('verify-form')?.addEventListener('submit', (e) => this.handleVerify(e));
        document.getElementById('login-form')?.addEventListener('submit', (e) => this.handleLogin(e));
        document.getElementById('logout-btn')?.addEventListener('click', () => this.handleLogout());
        document.getElementById('task-form')?.addEventListener('submit', (e) => this.handleAddTask(e));
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.handleFilterChange(e));
        });

        // Delete modal events
        document.getElementById('cancel-delete')?.addEventListener('click', () => this.hideDeleteModal());
        document.getElementById('confirm-delete')?.addEventListener('click', () => this.confirmDelete());
        document.getElementById('delete-modal')?.addEventListener('click', (e) => {
            if (e.target.id === 'delete-modal') this.hideDeleteModal();
        });
    }

    showPage(pageId) {
        document.querySelectorAll('.page').forEach(page => page.classList.remove('active'));
        document.getElementById(pageId).classList.add('active');
        this.clearMessages();
    }
    
    showLoading() {
        document.getElementById('loading-overlay').classList.add('show');
    }

    hideLoading() {
        document.getElementById('loading-overlay').classList.remove('show');
    }

    showMessage(elementId, message, type = 'error') {
        const messageEl = document.getElementById(elementId);
        messageEl.textContent = message;
        messageEl.className = `message ${type} show`;
    }

    clearMessages() {
        document.querySelectorAll('.message').forEach(msg => {
            msg.classList.remove('show');
        });
    }

    checkAuthState() {
        if (auth.isAuthenticated()) {
            this.loadApp();
        } else {
            this.showPage('landing-page');
        }
    }

    async handleSignup(e) {
        e.preventDefault();
        this.clearMessages();

        const email = document.getElementById('signup-email').value.trim();
        const password = document.getElementById('signup-password').value;
        const confirmPassword = document.getElementById('signup-confirm').value;

        if (password !== confirmPassword) {
            this.showMessage('signup-message', 'Passwords do not match', 'error');
            return;
        }

        if (password.length < 8) {
            this.showMessage('signup-message', 'Password must be at least 8 characters', 'error');
            return;
        }

        if (!/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) {
            this.showMessage('signup-message', 'Password must contain uppercase, lowercase, and numbers', 'error');
            return;
        }

        this.showLoading();

        try {
            await auth.signUp(email, password);
            this.hideLoading();
            
            document.getElementById('verify-email').textContent = email;
            localStorage.setItem('pendingVerificationEmail', email);
            
            this.showPage('verify-page');
            this.showMessage('verify-message', 'Verification code sent to your email', 'success');
        } catch (error) {
            this.hideLoading();
            this.showMessage('signup-message', error.message, 'error');
        }
    }

    async handleVerify(e) {
        e.preventDefault();
        this.clearMessages();

        const code = document.getElementById('verify-code').value.trim();
        const email = localStorage.getItem('pendingVerificationEmail');

        if (!email) {
            this.showMessage('verify-message', 'Session expired. Please sign up again.', 'error');
            return;
        }

        this.showLoading();

        try {
            await auth.confirmSignUp(email, code);
            this.hideLoading();
            
            localStorage.removeItem('pendingVerificationEmail');
            
            this.showPage('login-page');
            this.showMessage('login-message', 'Account verified! Please login.', 'success');
        } catch (error) {
            this.hideLoading();
            this.showMessage('verify-message', error.message, 'error');
        }
    }

    async handleLogin(e) {
        e.preventDefault();
        this.clearMessages();

        const email = document.getElementById('login-email').value.trim();
        const password = document.getElementById('login-password').value;

        this.showLoading();

        try {
            await auth.signIn(email, password);
            this.hideLoading();
            this.loadApp();
        } catch (error) {
            this.hideLoading();
            
            let errorMessage = error.message;
            if (errorMessage.includes('UserNotConfirmedException')) {
                errorMessage = 'Please verify your email first. Check your inbox for the verification code.';
                document.getElementById('verify-email').textContent = email;
                localStorage.setItem('pendingVerificationEmail', email);
                this.showPage('verify-page');
                return;
            } else if (errorMessage.includes('NotAuthorizedException')) {
                errorMessage = 'Incorrect email or password';
            }
            
            this.showMessage('login-message', errorMessage, 'error');
        }
    }

    handleLogout() {
        auth.signOut();
        this.tasks = [];
        this.showPage('landing-page');
    }

    async loadApp() {
        this.showPage('app-page');
        document.getElementById('user-email').textContent = auth.getCurrentUserEmail();
        
        this.showLoading();
        try {
            await this.loadTasks();
        } catch (error) {
            console.error('Error loading tasks:', error);
            alert('Error loading tasks. Please try again.');
        } finally {
            this.hideLoading();
        }
    }

    async loadTasks() {
        try {
            const response = await api.getTasks();
            console.log('Raw tasks from API:', JSON.stringify(response, null, 2));
            this.tasks = response;
            this.renderTasks();
        } catch (error) {
            console.error('Error loading tasks:', error);
            throw error;
        }
    }

    async handleAddTask(e) {
        e.preventDefault();

        const input = document.getElementById('task-input');
        const title = input.value.trim();

        if (!title) return;

        this.showLoading();

        try {
            const newTask = await api.createTask(title);
            this.tasks.unshift(newTask);
            this.renderTasks();
            input.value = '';
        } catch (error) {
            alert('Error creating task: ' + error.message);
        } finally {
            this.hideLoading();
        }
    }

    async handleToggleTask(taskId, completed) {
        this.showLoading();

        try {
            await api.updateTask(taskId, completed);
            
            const task = this.tasks.find(t => t.taskId === taskId);
            if (task) {
                task.completed = completed;
                this.renderTasks();
            }
        } catch (error) {
            alert('Error updating task: ' + error.message);
            this.renderTasks();
        } finally {
            this.hideLoading();
        }
    }

    async handleDeleteTask(taskId) {
        console.log('handleDeleteTask called with taskId:', taskId);
        if (!taskId || taskId === 'null' || taskId === 'undefined') {
            console.error('Invalid taskId for delete:', taskId);
            alert('Error: Invalid task ID');
            return;
        }
        this.pendingDeleteTaskId = taskId;
        document.getElementById('delete-modal').classList.add('show');
    }

    hideDeleteModal() {
        this.pendingDeleteTaskId = null;
        document.getElementById('delete-modal').classList.remove('show');
    }

    async confirmDelete() {
        const taskIdToDelete = this.pendingDeleteTaskId;
        console.log('confirmDelete called, taskIdToDelete:', taskIdToDelete);
        if (!taskIdToDelete) {
            console.error('No pending delete task ID');
            return;
        }

        this.hideDeleteModal();
        this.showLoading();

        try {
            console.log('About to call api.deleteTask with:', taskIdToDelete);
            console.log('Type of taskIdToDelete:', typeof taskIdToDelete);
            const result = await api.deleteTask(taskIdToDelete);
            console.log('api.deleteTask result:', result);
            this.tasks = this.tasks.filter(t => t.taskId !== taskIdToDelete);
            this.renderTasks();
        } catch (error) {
            console.error('Error in confirmDelete:', error);
            alert('Error deleting task: ' + error.message);
        } finally {
            this.hideLoading();
        }
    }

    async handleGetUploadUrl(taskId) {
        if (this.uploadingTaskId) return;

        const fileInput = document.createElement('input');
        fileInput.type = 'file';
        fileInput.accept = '.png,.jpg,.jpeg';
        
        fileInput.onchange = async (e) => {
            const file = e.target.files[0];
            if (!file) return;

            this.uploadingTaskId = taskId;
            this.renderTasks();

            try {
                const { uploadURL } = await api.getUploadUrl(taskId);
                
                const xhr = new XMLHttpRequest();
                
                xhr.upload.onprogress = (event) => {
                    if (event.lengthComputable) {
                        const percentComplete = (event.loaded / event.total) * 100;
                        const progressBar = document.querySelector(`li[data-task-id="${taskId}"] .progress-fill`);
                        if (progressBar) {
                            progressBar.style.width = percentComplete + '%';
                        }
                    }
                };

                await new Promise((resolve, reject) => {
                    xhr.onload = () => {
                        if (xhr.status >= 200 && xhr.status < 300) {
                            resolve(null);
                        } else {
                            reject(new Error('Failed to upload file'));
                        }
                    };
                    xhr.onerror = () => reject(new Error('Upload failed'));
                    xhr.open('PUT', uploadURL, true);
                    xhr.setRequestHeader('Content-Type', file.type);
                    xhr.send(file);
                });

                // Upload complete - progress bar will show 100%
                const progressBar = document.querySelector(`li[data-task-id="${taskId}"] .progress-fill`);
                if (progressBar) {
                    progressBar.style.width = '100%';
                }
            } catch (error) {
                alert('Error uploading file: ' + error.message);
            } finally {
                setTimeout(() => {
                    this.uploadingTaskId = null;
                    this.renderTasks();
                }, 500);
            }
        };

        fileInput.click();
    }

    handleFilterChange(e) {
        const filter = e.target.dataset.filter;
        this.currentFilter = filter;

        document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
        e.target.classList.add('active');

        this.renderTasks();
    }

    getFilteredTasks() {
        switch (this.currentFilter) {
            case 'active':
                return this.tasks.filter(task => !task.completed);
            case 'completed':
                return this.tasks.filter(task => task.completed);
            default:
                return this.tasks;
        }
    }

    renderTasks() {
        const taskList = document.getElementById('task-list');
        const emptyState = document.getElementById('empty-state');
        
        const filteredTasks = this.getFilteredTasks();

        if (filteredTasks.length === 0) {
            taskList.innerHTML = '';
            emptyState.style.display = 'block';
            return;
        }

        emptyState.style.display = 'none';

        taskList.innerHTML = filteredTasks.map(task => {
            const taskId = task.taskId || task.id;
            if (!taskId) {
                console.error('Task has no ID, skipping:', task);
                return '';
            }
            
            console.log('Rendering task with ID:', taskId);
            const date = new Date(task.createdAt);
            const formattedDate = date.toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
                year: 'numeric'
            });

            const isUploading = this.uploadingTaskId === taskId;
            const isAnotherUploading = this.uploadingTaskId && this.uploadingTaskId !== taskId;

            return `
                <li class="task-item ${task.completed ? 'completed' : ''} ${isUploading ? 'uploading' : ''}" data-task-id="${taskId}">
                    <label class="task-checkbox-wrapper">
                        <input 
                            type="checkbox" 
                            ${task.completed ? 'checked' : ''}
                            onchange="app.handleToggleTask('${taskId}', this.checked)"
                        >
                        <span class="checkbox-custom"></span>
                    </label>
                    <div class="task-item-content">
                        <div class="task-row">
                            <span class="task-content">${this.escapeHtml(task.title)}</span>
                            <span class="task-date">${formattedDate}</span>
                            <div class="task-item-buttons">
                                <button 
                                    class="btn btn-secondary btn-upload" 
                                    onclick="app.handleGetUploadUrl('${taskId}')"
                                    ${isAnotherUploading ? 'disabled' : ''}
                                >
                                    ${isUploading ? 'Uploading...' : 'Upload'}
                                </button>
                                <button 
                                    class="btn btn-danger" 
                                    onclick="app.handleDeleteTask('${taskId}')"
                                    ${isAnotherUploading ? 'disabled' : ''}
                                >
                                    Delete
                                </button>
                            </div>
                        </div>
                        ${isUploading ? `
                            <div class="progress-bar">
                                <div class="progress-fill" style="width: 0%"></div>
                            </div>
                        ` : ''}
                    </div>
                </li>
            `;
        }).join('');
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

document.addEventListener('DOMContentLoaded', () => {
    window.app = new CloudTaskApp();
});
