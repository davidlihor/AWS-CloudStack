class API {
    constructor() {
        this.baseURL = AWS_CONFIG.apiEndpoint;
    }

    getAuthHeaders() {
        const token = auth.getIdToken();
        return {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
        };
    }

    async handleResponse(response) {
        if (response.status === 401) {
            try {
                await auth.refreshSession();
                throw new Error('Session expired. Please try again.');
            } catch (error) {
                auth.signOut();
                window.location.reload();
                throw new Error('Session expired. Please login again.');
            }
        }

        const data = await response.json();
        if (!response.ok) {
            throw new Error(data.error || data.message || 'Request failed');
        }

        return data;
    }

    async getTasks() {
        try {
            const response = await fetch(`${this.baseURL}/tasks`, {
                method: 'GET',
                headers: this.getAuthHeaders()
            });

            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error fetching tasks:', error);
            throw error;
        }
    }

    async createTask(title) {
        try {
            const response = await fetch(`${this.baseURL}/tasks`, {
                method: 'POST',
                headers: this.getAuthHeaders(),
                body: JSON.stringify({ title })
            });

            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error creating task:', error);
            throw error;
        }
    }

    async updateTask(taskId, completed) {
        try {
            const response = await fetch(`${this.baseURL}/tasks/${taskId}`, {
                method: 'PUT',
                headers: this.getAuthHeaders(),
                body: JSON.stringify({ completed })
            });

            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error updating task:', error);
            throw error;
        }
    }

    async deleteTask(taskId) {
        try {
            const response = await fetch(`${this.baseURL}/tasks/${taskId}`, {
                method: 'DELETE',
                headers: this.getAuthHeaders()
            });

            return await this.handleResponse(response);
        } catch (error) {
            console.error('Error deleting task:', error);
            throw error;
        }
    }
}

window.api = new API();
