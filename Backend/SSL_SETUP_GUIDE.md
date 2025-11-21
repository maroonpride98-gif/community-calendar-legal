# SSL/HTTPS Setup Guide for Community Calendar

HTTPS is **required** for production deployment. This guide shows you how to set up SSL/HTTPS for your Community Calendar backend.

## Why HTTPS is Required

1. **Security**: Encrypts data in transit (passwords, tokens, personal data)
2. **Browser Requirements**: Modern browsers require HTTPS for many features
3. **PWA Requirements**: Progressive Web Apps only work with HTTPS
4. **Trust**: Users expect the padlock icon
5. **SEO**: Google ranks HTTPS sites higher

---

## Option 1: Let's Encrypt (Free SSL - Recommended)

Let's Encrypt provides free SSL certificates that auto-renew.

### For Nginx (Most Common)

#### 1. Install Certbot

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx
```

**CentOS/RHEL:**
```bash
sudo yum install certbot python3-certbot-nginx
```

#### 2. Obtain Certificate

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Certbot will:
- Verify domain ownership
- Generate SSL certificate
- Configure Nginx automatically
- Set up auto-renewal

#### 3. Test Auto-Renewal

```bash
sudo certbot renew --dry-run
```

#### 4. Nginx Configuration Example

Certbot modifies your Nginx config, but here's what it looks like:

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # SSL Certificate
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # API Proxy
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Web App (if hosting frontend)
    location / {
        root /var/www/community-calendar;
        try_files $uri $uri/ /index.html;
    }
}
```

### For Apache

#### 1. Install Certbot

```bash
sudo apt-get install certbot python3-certbot-apache
```

#### 2. Obtain Certificate

```bash
sudo certbot --apache -d yourdomain.com -d www.yourdomain.com
```

---

## Option 2: Cloudflare (Free + CDN)

Cloudflare provides free SSL and acts as a reverse proxy/CDN.

### Setup Steps

1. **Sign up** at [cloudflare.com](https://cloudflare.com)

2. **Add your domain** to Cloudflare

3. **Update nameservers** at your domain registrar to Cloudflare's nameservers

4. **Enable SSL**:
   - Go to SSL/TLS → Overview
   - Select **"Full (strict)"** mode

5. **Create DNS records**:
   ```
   Type: A
   Name: @
   Content: YOUR_SERVER_IP

   Type: A
   Name: www
   Content: YOUR_SERVER_IP

   Type: A
   Name: api
   Content: YOUR_SERVER_IP
   ```

6. **Enable "Always Use HTTPS"**:
   - SSL/TLS → Edge Certificates → Always Use HTTPS: ON

### Benefits

- Free SSL certificate
- Global CDN
- DDoS protection
- Automatic HTTPS redirects
- Page Rules for caching

---

## Option 3: Cloud Platform SSL (Automatic)

Most cloud platforms provide automatic SSL.

### Netlify (Web App)

1. Deploy site to Netlify
2. Add custom domain in Site Settings
3. SSL is automatic and free!

### Vercel (Web App)

1. Deploy to Vercel
2. Add custom domain
3. SSL auto-configured

### Heroku (Backend API)

1. Deploy app to Heroku
2. Add custom domain:
   ```bash
   heroku domains:add api.yourdomain.com
   ```
3. Enable Automated Certificate Management (ACM):
   ```bash
   heroku certs:auto:enable
   ```
4. Update DNS:
   ```
   Type: CNAME
   Name: api
   Content: your-app-name.herokudns.com
   ```

### Railway (Backend API)

1. Deploy to Railway
2. Go to Settings → Domains
3. Add custom domain
4. SSL is automatic

### DigitalOcean App Platform

1. Deploy app
2. Add domain in Settings
3. SSL auto-configured

---

## Option 4: Self-Signed Certificate (Development Only)

⚠️ **NOT for production** - Only use for local testing.

### Generate Certificate

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx-selfsigned.key \
  -out /etc/ssl/certs/nginx-selfsigned.crt
```

### Nginx Config

```nginx
server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    location /api/ {
        proxy_pass http://localhost:3000;
    }
}
```

---

## Testing Your SSL Setup

### 1. SSL Labs Test

Visit: https://www.ssllabs.com/ssltest/analyze.html?d=yourdomain.com

Should get **A or A+** rating.

### 2. Command Line Test

```bash
curl -I https://yourdomain.com
```

Should return `HTTP/2 200` or `HTTP/1.1 200`

### 3. Browser Test

1. Visit `https://yourdomain.com`
2. Check for padlock icon
3. Click padlock → Certificate should be valid

---

## Troubleshooting

### "Certificate Not Valid" Error

**Check domain ownership:**
```bash
dig yourdomain.com
```
Make sure it points to your server IP.

**Verify certificate files:**
```bash
sudo certbot certificates
```

### Mixed Content Warnings

Ensure your app uses HTTPS for **all** resources:
- API calls: `https://api.yourdomain.com`
- Assets: `https://yourdomain.com/assets/...`

### Certificate Expired

Let's Encrypt certificates last 90 days. Check auto-renewal:
```bash
sudo systemctl status certbot.timer
```

Manually renew:
```bash
sudo certbot renew
```

---

## Production Checklist

Before going live:

- [ ] SSL certificate installed and valid
- [ ] HTTPS redirect configured (HTTP → HTTPS)
- [ ] Certificate auto-renewal set up
- [ ] SSL Labs test shows A or A+
- [ ] All API calls use HTTPS
- [ ] No mixed content warnings
- [ ] HSTS header enabled (optional but recommended)
- [ ] Certificate expiry monitoring set up

---

## HSTS (HTTP Strict Transport Security)

Add this header for extra security:

**Nginx:**
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

**Node.js (with helmet):**
```javascript
app.use(helmet({
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true
  }
}));
```

---

## Cost Comparison

| Option | Cost | Difficulty | Renewal |
|--------|------|------------|---------|
| Let's Encrypt | Free | Easy | Auto |
| Cloudflare | Free | Easy | Auto |
| Cloud Platforms | Free | Very Easy | Auto |
| Paid SSL | $10-100/year | Medium | Manual/Auto |

**Recommendation**: Use **Let's Encrypt** (free, trusted, auto-renews) or **Cloudflare** (free + CDN benefits).

---

## Next Steps

After SSL is configured:

1. Update `Config.gd` with HTTPS URLs
2. Test all API endpoints with HTTPS
3. Deploy web app to HTTPS-enabled host
4. Test on mobile devices
5. Monitor certificate expiration

---

**Need Help?** Check the official docs:
- Let's Encrypt: https://letsencrypt.org/getting-started/
- Cloudflare: https://support.cloudflare.com/hc/en-us/articles/205893698
- Certbot: https://certbot.eff.org/
