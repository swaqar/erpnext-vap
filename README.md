# ERPNext VAP Git - Multi-Site Deployment

A production-ready ERPNext deployment solution with Docker containerization, multi-site support, and cloud deployment capabilities. This project provides a hardened ERPNext setup with MariaDB, Redis caching, and NGINX reverse proxy with SSL support. Built specifically for Virtuozzo Application Platform (VAP) with automatic site creation and production-ready configuration.

## 🚀 Features

- **Dockerized ERPNext**: Containerized deployment using Python 3.10
- **Multi-Site Support**: Deploy multiple ERPNext sites on a single instance
- **Production Ready**: Includes production mode setup with Supervisor
- **Database Integration**: MariaDB/MySQL database support
- **Redis Caching**: Optional Redis integration for improved performance
- **NGINX Reverse Proxy**: SSL-enabled reverse proxy configuration
- **Cloud Deployment**: JPS (Virtuozzo Application Platform Script) for cloud deployment
- **Environment Configuration**: Flexible environment variable configuration

## 📁 Project Structure

```
erpnext-vap-git/
├── Dockerfile              # Main application container
├── entrypoint.sh           # Container initialization script
├── jps/
│   └── erpnext-multisite.jps  # Jelastic deployment configuration
└── nginx/
    └── erp.conf            # NGINX reverse proxy configuration
```

## 🛠️ Components

### 1. Dockerfile
- Based on Python 3.10 slim Debian Bullseye (hardened, minimal attack surface)
- Installs system dependencies (MariaDB client, Redis tools, Node.js, etc.)
- Creates `frappe` user with sudo privileges
- Installs Frappe Bench CLI and ERPNext application
- Exposes ports 8000 (web) and 9000 (socketio)
- Production-ready with security hardening

### 2. Entrypoint Script
- Configures Redis connections (if available)
- Creates new ERPNext sites automatically based on environment name
- Installs ERPNext application on sites
- Sets up production mode with Supervisor
- Handles environment variable configuration
- Auto-generates site names from JPS environment variables

### 3. JPS Configuration
- Multi-node deployment setup for Virtuozzo Application Platform
- MariaDB 10.6+ database node (compatible with ERPNext requirements)
- Redis cache node (optional)
- ERPNext application node with hardened Docker image
- NGINX proxy node with Let's Encrypt SSL
- Automatic SSL certificate management
- Environment-based site naming (${env.name}.local)

### 4. NGINX Configuration
- SSL/TLS termination
- Reverse proxy to ERPNext application
- Proper header forwarding
- Let's Encrypt certificate integration

## 🚀 Deployment Options

### Option 1: Docker Compose (Local Development)

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  mariadb:
    image: mariadb:10.6
    environment:
      MYSQL_ROOT_PASSWORD: your_root_password
      MYSQL_DATABASE: erpnext
      MYSQL_USER: frappe
      MYSQL_PASSWORD: your_password
    volumes:
      - mariadb_data:/var/lib/mysql
    ports:
      - "3306:3306"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  erpnext:
    image: swaqar/erpnext-hardened:latest
    environment:
      SITE_NAME: ${ENV_NAME:-mysite.local}
      ADMIN_PASSWORD: admin
      DB_HOST: mariadb
      DB_PORT: 3306
      DB_USER: root
      DB_PASSWORD: your_root_password
      REDIS_HOST: redis
      REDIS_PORT: 6379
      FRAPPE_USER: frappe
    ports:
      - "8000:8000"
      - "9000:9000"
    depends_on:
      - mariadb
      - redis
    volumes:
      - erpnext_sites:/home/frappe/frappe-bench/sites

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/erp.conf:/etc/nginx/conf.d/default.conf
      - ./ssl:/etc/letsencrypt
    depends_on:
      - erpnext

volumes:
  mariadb_data:
  erpnext_sites:
```

### Option 2: Cloud Deployment (Virtuozzo Application Platform)

1. **Upload JPS File**: Upload `jps/erpnext-multisite.jps` to your Virtuozzo Application Platform environment
2. **Deploy**: Execute the JPS script with your domain and credentials
3. **Access**: Navigate to your domain to access ERPNext

### Option 3: Manual Docker Deployment

```bash
# 1. Pull the image
docker pull swaqar/erpnext-hardened:latest

# 2. Run the container
docker run -d \
  --name erpnext \
  -p 8000:8000 \
  -p 9000:9000 \
  -e SITE_NAME=your-env-name.local \
  -e ADMIN_PASSWORD=admin \
  -e DB_HOST=your_db_host \
  -e DB_PASSWORD=your_db_password \
  -e REDIS_HOST=your_redis_host \
  swaqar/erpnext-hardened:latest
```

## ⚙️ Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SITE_NAME` | `${env.name}.local` | ERPNext site name (auto-generated from environment name) |
| `ADMIN_PASSWORD` | `admin` | Admin user password |
| `DB_HOST` | `mariadb` | Database host |
| `DB_PORT` | `3306` | Database port |
| `DB_USER` | `root` | Database user |
| `DB_PASSWORD` | `root` | Database password |
| `REDIS_HOST` | - | Redis host (optional) |
| `REDIS_PORT` | `6379` | Redis port |
| `FRAPPE_USER` | `frappe` | Frappe system user |

## 🔧 Configuration

### Database Setup
The application automatically creates the database and user if they don't exist. **Important**: This deployment requires MariaDB 10.6+ for compatibility with ERPNext. The JPS configuration uses the correct MariaDB version to avoid schema creation issues.

### Redis Configuration (Optional)
Redis is used for:
- Session caching
- Queue management
- Socket.IO connections

If Redis is not provided, the application will run without caching.

### SSL/HTTPS Setup
For production deployments:
1. Obtain SSL certificates (Let's Encrypt recommended)
2. Update NGINX configuration with certificate paths
3. Configure domain in ERPNext site settings

## 📊 Monitoring and Maintenance

### Logs
```bash
# View application logs
docker logs erpnext

# View NGINX logs
docker logs nginx
```

### Backup
```bash
# Backup ERPNext sites
docker exec erpnext bench backup

# Backup database
docker exec mariadb mysqldump -u root -p erpnext > backup.sql
```

### Updates
```bash
# Update ERPNext
docker exec erpnext bench update

# Update Frappe Framework
docker exec erpnext bench update --apps frappe
```

## 🔒 Security Considerations

- **Hardened Base Image**: Uses Python 3.10 slim Debian Bullseye instead of Ubuntu to reduce vulnerabilities
- Change default admin password immediately after deployment
- Use strong database passwords
- Enable SSL/TLS in production (Let's Encrypt via VAP)
- Regularly update dependencies
- Monitor access logs
- Implement proper firewall rules
- **Non-root User**: Application runs as `frappe` user for enhanced security

## 🐛 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Verify database host and credentials
   - Check network connectivity
   - Ensure database service is running
   - **MariaDB Version**: Ensure you're using MariaDB 10.6+ (older versions cause schema issues)

2. **Site Creation Fails**
   - Check database permissions
   - Verify site name format (should be `${env.name}.local`)
   - Review application logs
   - Ensure `bench` CLI is properly installed in virtual environment

3. **Redis Connection Issues**
   - Verify Redis host and port
   - Check Redis service status
   - Review Redis configuration

4. **SSL Certificate Errors**
   - Verify certificate paths in NGINX config
   - Check certificate validity
   - Ensure proper file permissions

### Debug Mode
To run in debug mode, modify the entrypoint script to skip production setup:

```bash
# Comment out production setup in entrypoint.sh
# sudo bench setup production "$FRAPPE_USER"
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [Frappe Framework](https://frappeframework.com/)
- [ERPNext](https://erpnext.com/)
- [Virtuozzo PaaS Cloud Hosting](https://www.virtuozzo.com/paas-cloud-hosting/)

## 📞 Support

For support and questions:
- Create an issue in this repository
- Check ERPNext documentation
- Visit Frappe community forums

## 🎯 **Why This Project Was Built**

Based on extensive testing and real-world deployment challenges:

### **Problems Solved:**
1. **Production ERPNext Complexity**: Traditional ERPNext deployments require extensive manual configuration
2. **Security Vulnerabilities**: Official images use Ubuntu 22.04 with known CVEs
3. **VAP Integration**: Lack of native Virtuozzo Application Platform support
4. **Multi-Site Management**: Difficult to deploy and manage multiple ERPNext instances
5. **Database Compatibility**: MariaDB version mismatches causing schema creation failures

### **Key Innovations:**
- **Hardened Docker Image**: Uses Python 3.10 slim Debian Bullseye for minimal attack surface
- **Auto-Site Creation**: Automatically creates sites based on environment names
- **VAP-Optimized**: Designed specifically for Virtuozzo Application Platform deployment
- **Production Ready**: Includes Supervisor, proper user isolation, and SSL termination
- **Redis Optional**: Gracefully handles Redis availability for caching

---

**Note**: This is a production-ready deployment solution. Always test in a staging environment before deploying to production. 