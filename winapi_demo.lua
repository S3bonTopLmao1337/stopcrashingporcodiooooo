setfenv(1, require'winapi')
--functions
require'winapi.monitor'
require'winapi.cursor'
--standard controls
require'winapi.windowclass'
require'winapi.menuclass'
require'winapi.buttonclass'
require'winapi.toolbarclass'
require'winapi.groupboxclass'
require'winapi.checkboxclass'
require'winapi.radiobuttonclass'
require'winapi.editclass'
require'winapi.tabcontrolclass'
require'winapi.listboxclass'
require'winapi.comboboxclass'
require'winapi.labelclass'
require'winapi.listviewclass'
require'winapi.trackbarclass'
--panels
require'winapi.bitmappanel'
local have_wgl   = pcall(require, 'winapi.wglpanel')
local have_cairo = pcall(require, 'winapi.cairopanel')

--get the monitor where the mouse is right now. ------------------------------

local mon = MonitorFromPoint(GetCursorPos(), MONITOR_DEFAULTTONEAREST)
local moninfo = GetMonitorInfo(mon)

--create the main window -----------------------------------------------------

local w, h = 550, 550
local win = Window{
	x = (moninfo.work_rect.w - w) / 2, --center the window on the monitor
	y = (moninfo.work_rect.h - h) / 2,
	w = w,
	h = h,
	title = (' '):rep(50)..' ┬┴┬┴┤ Lua Rulez ├┬┴┬┴',
	autoquit = true, --quit the app when the window is closed
}

--create and show an about box -----------------------------------------------

local function about_box()

	local w, h = 300, 200
	local aboutwin = Window{
		x = win.x + (win.w - w) / 2, --center the window on its parent
		y = win.y + (win.h - h) / 2,
		w = 300,
		h = 200,
		title = 'About winapi',
		maximizable = false,
		minimizable = false,
		resizeable = false,
		owner = win, --don't show it in taskbar
		tool_window = true,
	}

	local w, h = 100, 24
	local okbtn = Button{
		x = (aboutwin.client_w - w) / 2,
		y = aboutwin.client_h * 5/6 - h,
		w = w, h = h,
		parent = aboutwin,
		default = true, --respond to pressing Enter
	}

	local lb = Label{
		x = 0, y = 40,
		w = aboutwin.client_w,
		h = aboutwin.client_h,
		parent = aboutwin,
		align = 'center',
		text = 'Windows API Binding Demo',
	}

	--make it modal
	function okbtn:on_click()
		aboutwin:close()
	end
	function aboutwin:on_close()
		win:enable()
	end
	aboutwin.__wantallkeys = true --give us the ESC key!
	function okbtn:on_key_down(vk)
		if vk == VK_ESCAPE then
			aboutwin:close()
		end
	end
	win:disable()

	okbtn:focus()
end

--create menus for the main menu bar -----------------------------------------

local filemenu = Menu{
	items = {
		{text = '&Close', on_click = function() win:close() end},
	},
}

local aboutmenu = Menu{
	items = {
		{text = '&About', on_click = about_box},
	},
}

--create the main menu bar ---------------------------------------------------

local menubar = MenuBar()
menubar.items:add{text = '&File', submenu = filemenu}
menubar.items:add{text = '&About', submenu = aboutmenu}
win.menu = menubar

--create a toolbar -----------------------------------------------------------

require'winapi.showcase'

local toolbar = Toolbar{
	parent = win,
	image_list = ImageList{w = 16, h = 16, masked = true, colors = '32bit'},
	items = {
		--NOTE: using `iBitmap` instead of `i` because `i` counts from 1
		{iBitmap = STD_FILENEW,  text = 'New'},
		{iBitmap = STD_FILEOPEN, text = 'Open'},
		{iBitmap = STD_FILESAVE, text = 'Save'},
	},
}
toolbar:load_images(IDB_STD_SMALL_COLOR)

--create a group box ---------------------------------------------------------

local groupbox1 = GroupBox{
	parent = win,
	x = 20,
	y = 180,
	w = 100,
	h = 170,
	text = 'Group 1',
}

local groupbox2 = GroupBox{
	parent = win,
	x = 140,
	y = 180,
	w = 100,
	h = 170,
	text = 'Group 2',
}

--create radio buttons -------------------------------------------------------

for i = 1, 5 do
	RadioButton{
		parent = groupbox1,
		x = 20,
		y = 10 + i * 22,
		w = 60,
		text = 'Option &'..i,
		checked = i == 2,
	}
end

--create check boxes ---------------------------------------------------------

for i = 1, 5 do
	CheckBox{
		parent = groupbox2,
		x = 20,
		y = 10 + i * 22,
		w = 60,
		text = 'Option &'..i,
		checked = i == 3 or i == 5,
	}
end

--create a tab control -------------------------------------------------------

local tabs = TabControl{
	parent = win,
	x = 380,
	y = 70,
	w = 100,
	h = 100,
	anchors = 'ltr',
	items = {
		{text = 'Tab1',},
		{text = 'Tab2',},
	},
}

local tablabel = Label{
	parent = tabs,
	x = 10, y = 30,
	w = 50, h = 50,
	anchors = 'ltr',
}

function tabs:on_tab_change()
	tablabel.text = 'Selected tab: '..tostring(self.selected_index)
end

tabs:on_tab_change()

--create a bitmap panel ------------------------------------------------------

local bmppanel = BitmapPanel{w = 100, h = 100, x = 20, y = 70, parent = win}

function bmppanel:on_bitmap_paint(bmp)
	local p = self.cursor_pos
	local pixels = ffi.cast('uint8_t*', bmp.data)
	for y = 0, bmp.h - 1 do
		for x = 0, bmp.w - 1 do
			pixels[y * bmp.stride + x * 4 + 0] = x + p.x - 100
			pixels[y * bmp.stride + x * 4 + 1] = y + p.y - 100
			pixels[y * bmp.stride + x * 4 + 2] = x + p.x - 100
		end
	end
end

function bmppanel:on_mouse_move(x, y)
	self:invalidate()
end

--create a cairo panel -------------------------------------------------------

if have_cairo then

local cairo = require'cairo'
local cairopanel = CairoPanel{w = 100, h = 100, x = 140, y = 70, parent = win}

local r = 0
function cairopanel:on_cairo_paint(cr)
	cr:rgba(0,0,0,1)
	cr:paint()

	cr:identity_matrix()
	cr:translate(self.w/2, self.h/2)
	r = r + .02
	cr:rotate(r)
	cr:translate(-self.w/2, -self.h/2)
	cr:scale(0.4, 0.4)

	cr:rgba(0,0.7,0,1)

	cr:line_width(40.96)
	cr:move_to(76.8, 84.48)
	cr:rel_line_to(51.2, -51.2)
	cr:rel_line_to(51.2, 51.2)
	cr:line_join'miter'
	cr:stroke()

	cr:move_to(76.8, 161.28)
	cr:rel_line_to(51.2, -51.2)
	cr:rel_line_to(51.2, 51.2)
	cr:line_join'bevel'
	cr:stroke()

	cr:move_to(76.8, 238.08)
	cr:rel_line_to(51.2, -51.2)
	cr:rel_line_to(51.2, 51.2)
	cr:line_join'round'
	cr:stroke()
end

win:settimer(1/30, function()
	cairopanel:invalidate()
end)

end

--create a wglpanel ----------------------------------------------------------

if have_wgl then

local wglpanel = WGLPanel{w = 100, h = 100, x = 260, y = 70, parent = win}

local function cube(w, r)
	gl.glPushMatrix()
	gl.glTranslated(0,0,-3)
	gl.glScaled(w, w, 1)
	gl.glRotated(r,1,r,1)
	gl.glTranslated(0,0,2)
	local function face(c)
		gl.glBegin(gl.GL_QUADS)
		gl.glColor4d(c,0,0,.5)
		gl.glVertex3d(-1, -1, -1)
		gl.glColor4d(0,c,0,.5)
		gl.glVertex3d(1, -1, -1)
		gl.glColor4d(0,0,c,.5)
		gl.glVertex3d(1, 1, -1)
		gl.glColor4d(c,0,c,.5)
		gl.glVertex3d(-1, 1, -1)
		gl.glEnd()
	end
	gl.glTranslated(0,0,-2)
	face(1)
	gl.glTranslated(0,0,2)
	face(1)
	gl.glTranslated(0,0,-2)
	gl.glRotated(-90,0,1,0)
	face(1)
	gl.glTranslated(0,0,2)
	face(1)
	gl.glRotated(-90,1,0,0)
	gl.glTranslated(0,2,0)
	face(1)
	gl.glTranslated(0,0,2)
	face(1)
	gl.glPopMatrix()
end

function wglpanel:on_set_viewport()
	local w, h = self.w, self.h
	gl.glViewport(0, 0, w, h)
	gl.glMatrixMode(gl.GL_PROJECTION)
	gl.glLoadIdentity()
	gl.glFrustum(-1, 1, -1, 1, 1, 100) --so fov is 90 deg
	gl.glScaled(1, w/h, 1)
end

local r = 0
function wglpanel:on_render()
	gl.glClearColor(0, 0, 0, 1)
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))
	gl.glEnable(gl.GL_BLEND)
	gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_SRC_ALPHA)
	gl.glDisable(gl.GL_DEPTH_TEST)
	gl.glDisable(gl.GL_CULL_FACE)
	gl.glDisable(gl.GL_LIGHTING)
	gl.glMatrixMode(gl.GL_MODELVIEW)
	gl.glLoadIdentity()
	gl.glTranslated(0,0,-1)
	r = r + 2
	cube(2, r)
end

win:settimer(1/30, function()
	wglpanel:invalidate()
end)

end

--create some buttons --------------------------------------------------------

local closebtn = Button{
	x = win.client_w - 130,
	y = win.client_h - 40,
	w = 100,
	text = '&Close',
	parent = win,
	anchors = 'rb',
}

function closebtn:on_click()
	win:close()
end

win.min_cw = win.client_w
win.min_ch = win.client_h

--create a list box ----------------------------------------------------------

local lb = ListBox{parent = win, x = 260, y = 187, h = 160, hextent = 100}
for i = 1,100 do
	lb.items:add('ListBox item '..i)
end

--create an edit box ---------------------------------------------------------

local edit = Edit{parent = win, x = 380, y = 187, cue = 'Edit me'}

--create a combo box ---------------------------------------------------------

local combo = ComboBox{
	parent = win,
	x = 380,
	y = 220,
	type = 'dropdownlist',
	items = {
		{text = 'First item'},
		{text = 'Second item'},
	},
	selected_index = 2,
}

for i = 1, 10 do
	combo.items:add{text = 'Item '..i}
end

--create a slider ------------------------------------------------------------

local slider = Trackbar{
	parent = win,
	x = 370,
	y = 260,
	w = 120,
}

--create some labels ---------------------------------------------------------

local lb1 = Label{parent = win, x = 20, y = 50, text = 'BitmapPanel'}
local lb2 = Label{parent = win, x = 140, y = 50, text = 'CairoPanel'}
local lb3 = Label{parent = win, x = 260, y = 50, text = 'WGLPanel'}

--create an accelerator ------------------------------------------------------

win.accelerators:add{
	hotkey = 'escape', --VK_ESCAPE
	handler = function() win:close() end,
}

--create some list views -----------------------------------------------------

local rlv = ReportListView{
	parent = win,
	x = 20,
	y = 360,
	w = 220,
	h = 100,
	columns = {'name', 'address'},
	items = {
		{text = 'Louis Armstrong',  subitems = {'Basin Street'}},
		{text = 'Django Reinhardt', subitems = {'Beyond The Sea'}},
	},
}

--start the message loop -----------------------------------------------------

os.exit(MessageLoop())
