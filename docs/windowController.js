// windowController.js
// Handles draggable windows and taskbar syncing for the AeroBar Web OS Simulation

document.addEventListener('DOMContentLoaded', () => {
  const desktopBg = document.getElementById('desktop-bg');
  if (!desktopBg) return;
  
  let highestZ = 100;
  
  // Make a window draggable
  function makeDraggable(windowEl, headerEl) {
    let isDragging = false;
    let startX, startY, initialX, initialY;
    
    headerEl.addEventListener('mousedown', (e) => {
      // Don't drag if clicking buttons
      if (e.target.closest('.mac-dot')) return;
      
      isDragging = true;
      startX = e.clientX;
      startY = e.clientY;
      
      // Get current translation
      const style = window.getComputedStyle(windowEl);
      const matrix = new WebKitCSSMatrix(style.transform);
      initialX = matrix.m41;
      initialY = matrix.m42;
      
      // Bring to front
      highestZ++;
      windowEl.style.zIndex = highestZ;
      
      windowEl.style.transition = 'none'; // Disable transition for smooth dragging
    });
    
    document.addEventListener('mousemove', (e) => {
      if (!isDragging) return;
      
      const dx = e.clientX - startX;
      const dy = e.clientY - startY;
      
      windowEl.style.transform = `translate(${initialX + dx}px, ${initialY + dy}px)`;
    });
    
    document.addEventListener('mouseup', () => {
      if (isDragging) {
        isDragging = false;
        windowEl.style.transition = 'opacity 0.2s'; // Restore simple transitions if needed
      }
    });
  }

  // Hook into existing global function
  window.openMaximizedFromData = function(data) {
    openMaximizedFromData(data);
  };

  // Pre-open specific windows on load to replicate demo screenshot
  setTimeout(() => {
    openMaximizedFromData({
      title: 'Reddit - reddit.com',
      iconSrc: 'assets/dark-macosappicons/Reddit1.png',
      imageSrc: 'assets/previews/3. Reddit.png',
      defaultLeft: '2%',
      defaultTop: '8%',
      defaultWidth: '600px',
      defaultHeight: 'auto'
    });
    openMaximizedFromData({
      title: 'VS Code',
      iconSrc: 'assets/vscode.png',
      imageSrc: 'assets/previews/2. VS Code.png',
      defaultLeft: '20%',
      defaultTop: '20%',
      defaultWidth: '600px',
      defaultHeight: 'auto'
    });
    openMaximizedFromData({
      title: 'Safari - Docs',
      iconSrc: 'assets/safari.png',
      imageSrc: 'assets/previews/9. Safari.png',
      defaultLeft: '40%',
      defaultTop: '35%',
      defaultWidth: '600px',
      defaultHeight: 'auto'
    });
  }, 400); // Slight delay ensures styles and layout are ready

  function openMaximizedFromData(data) {
    const { defaultLeft, defaultTop, defaultWidth, defaultHeight } = data;
    // If there's an existing window for this app, bring it to front
    const winId = 'floating-window-' + data.title.replace(/[^a-zA-Z0-9]/g, '');
    const existing = document.getElementById(winId);
    if (existing) {
      existing.style.display = 'flex';
      highestZ++;
      existing.style.zIndex = highestZ;
      return;
    }
    
    // Create new floating window
    const win = document.createElement('div');
    win.className = 'maximized-window floating-window';
    win.id = winId;
    
    // Cascading logic
    const existingWins = document.querySelectorAll('.floating-window').length;
    const offset = (existingWins % 8) * 32; // Cascade offset
    
    win.style.position = 'absolute';
    win.style.width = defaultWidth || '700px';
    win.style.height = defaultHeight || '480px';
    
    // Placement
    win.style.left = defaultLeft || `calc(10% + ${offset}px)`;
    win.style.top = defaultTop || `calc(8% + ${offset}px)`;
    win.style.transform = 'none'; // Dragging will apply translation on top of this
    win.style.opacity = '1';
    win.style.pointerEvents = 'auto';
    win.style.display = 'flex';
    highestZ++;
    win.style.zIndex = highestZ;
    
    // Header
    const header = document.createElement('div');
    header.className = 'maximized-header';
    header.style.cursor = 'grab';
    
    const controls = document.createElement('div');
    controls.className = 'maximized-controls';
    controls.innerHTML = `
      <div class="mac-dot red" onclick="this.closest('.floating-window').remove()"></div>
      <div class="mac-dot yellow" onclick="this.closest('.floating-window').style.display='none'"></div>
      <div class="mac-dot green"></div>
    `;
    
    const titleArea = document.createElement('div');
    titleArea.className = 'maximized-title';
    titleArea.style.display = 'flex';
    titleArea.style.alignItems = 'center';
    titleArea.style.gap = '8px';
    titleArea.style.justifyContent = 'center';
    titleArea.style.flex = '1';
    
    if (data.emojiIcon) {
      titleArea.innerHTML = `<span class="emoji-icon">${data.emojiIcon}</span><span>${data.title}</span>`;
    } else {
      titleArea.innerHTML = `<img src="${data.iconSrc}" style="width:16px;height:16px;object-fit:contain;"><span>${data.title}</span>`;
    }
    
    header.appendChild(controls);
    header.appendChild(titleArea);
    
    // Body (Mocked Contents)
    const body = document.createElement('div');
    body.className = 'maximized-body';
    body.style.display = 'flex';
    body.style.flexDirection = 'column';
    body.style.flex = '1';
    
    // Inject custom HTML based on the app
    // Inject image preview or fallback text
    if (data.imageSrc) {
      body.innerHTML = `<img src="${data.imageSrc}">`;
    } else {
      body.innerHTML = `<div style="display:flex;align-items:center;justify-content:center;height:100%;color:#888;font-size:1.2rem;">${data.title} UI Loaded</div>`;
    }
    
    win.appendChild(header);
    win.appendChild(body);
    
    // Add to desktop
    desktopBg.appendChild(win);
    
    makeDraggable(win, header);
    
    // Click to focus
    win.addEventListener('mousedown', () => {
      highestZ++;
      win.style.zIndex = highestZ;
    });
    
    // Hide start menu if open
    document.querySelectorAll('.mock-popup').forEach(p => p.classList.remove('open'));
  };
  
});
