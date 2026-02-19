# KOReader Patches
Desription


<details open>
<summary><h2>For SCREEN SAVER</h2></summary>
 <p><i>These patches are applied to the Sleep Screen</i></p>

<details>
	<summary><b>Kobo-style Sleep Banner</b></summary>
<p>Redesigns the built-in 'banner' type sleep screen message to look like the native Kobo sleep screen style.<p/>

**Mod:**
* [x] Menu toggle: Turn On/Off the patch.
* [x] Menu toggle: "Avoid Night Mode" so the banner colors aren't inverted.
* [x] Added Smart Title Case with small words ignored to avoid All-Caps titles.
	
**Settings:** 

* Set your custom Sleep screen message in <i>`Settings > Screen > Sleep Screen > Sleep screen message > Edit sleep screen message`</i>, use the  <b>`info`</b> button for all the available variables.
* In <i>`Settings > Screen > Sleep Screen > Sleep screen message`</i> set <i>`Container and position`</i> to <b>`Banner`</b>. Set the `Message Opacy` and `Vertical position` for the box here as well.
* The patch adds the title followed by your custom sleep screen message. The default is Book title; you can change it inside the patch code.
* Settings inside the patch code: Text to use for title, bg color, margin, font, font size, border, border size and color.

<br/>
📌 Original patch by <a href="https://github.com/zenixlabs/koreader-frankenpatches-public/blob/main/2-kobo-style-sleepscreen-banner.lua">u/hundredpercentcocoa</a>
> I modded this patch before the "Highlights" feature was added.<br/>
<br/>

🗒️ **Notes:** 
> Since the cover already shows the book title, I set mine to show the current chapter followed by my custom message.  
> My custom message: pages left in chapter >> Time left in chapter. New Line with dashes. New line: Current page/total pages * % read. New line: Time left in book.  
> You can add new lines by pressing the ENTER key.

<img alt="Screenshot image of this patch" src="/screenshots/kobo-style-sleep-banner.jpg" width="400"/>

📂 [2-kobo-style-sleepscreen-banner.lua](/2-kobo-style-sleepscreen-banner.lua)
	 <br/> <br/>
	</details>

<details>
	<summary><b>Screensaver Utilities</b></summary> 
	
Adds 4 new toggles at the end of the "Sleep screen" menu:<br/>

* [x] Close widgets before showing the screensaver
* [x] Refresh before showing the screensaver
* [x] Force NO FILL for images when in File Browser
* [x] Center and shrink book cover

By default it doesn't change the sleep screen behavior.

<br/>
📌 Original patch by <a href="https://github.com/sebdelsol/KOReader.patches/blob/main/2-screensaver-cover.lua">sebdelsol</a>
> after Koreader change the screensaver widgets the patch needed an update, this patch  does not include the "No ovelap" feature form the original patch.
 <br/> <br/>

🗒️  **Notes:**  
>Force no fill: I have my screensvar set to `Ignore book cover` > `When in file browser` this mean that when my device goes to sleep while in file browser, custom images (which have transparent background) will show instead of the book cover, but since I want my book covers to have a fill when sleeping while in reader, this option will force to use `No fill` when sleeping in file browser without needing to change the fill manually. 

<img alt="Screenshot image of this patch" src="/screenshots/2-screensaver-utilities.png" width="400"/> 

   📂 [2-screensaver-utilities.lua](/2-screensaver-utilities.lua)
   <br/> <br/>
</details>	 	
</details>

<hr>	
<details open>
<summary><h2>For FILE BROWSER</h2></summary>
 <p><i>These patches are applied to the File Browser</i></p>
 
<details>
	<summary><b>Book Spine Effect</b></summary>
<br/>
Adds a realistic "book spine" effect simmilar to Apple Books to the edge of cover thumbnails in the Mosaic/Grid browser.  
<br/><br/>

**Settings:** 
* <ins>**Save**</ins> this image [book.spine.png](/icons/book.spine.png) inside the `koreader > icons` folder.	
* Settings inside the patch code: spine width, intensity and offset.
<br/><br/>

📌 Original patch by <a href="https://github.com/advokatb/KOReader-Patches/blob/main/2-pt-book-spine-effect.lua">advokatb</a>	

**Mod:**
* [x] Removed the rendering spine drawing.
* [x] Recreated the actual Apple Book spine images.
* [x] Add a shadow to the image so the spine is also visible on white covers.
* [x] Add a toggle in `Settings > Mosaic and detailed list settings` to turn ON/OFF the effect.
 <br/> <br/>

🗒️  **Notes:**  
> Even though the image and the code are optimized for better cache, this effect may consume a lot of memory and slow down your device, avoid using other heavy patches like recurring count, total page in book, etc.

<img alt="Screenshot image of this patch" src="/screenshots/screen-book-spine.png" width="600"/>

📂 [2-MM--Book-spine-effect.lua](/2-MM--Book-spine-effect.lua)
 <br/><br/>
	</details>

<details>
	<summary><b>Faded Cover Effect for Finished Books</b>👑 </summary>
Automatically reduces the opacity or greys out the covers of books that have been marked as "Finished" in the browser view.

📂 [View Code](/2-MM-faded-finished-books.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Browse by Metadata</b></summary>
Enhances the file browser capabilities, allowing for navigation and sorting based on specific book metadata tags.

📂 [View Code](/2-BrowseByMetadata.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Folder Cover</b></summary>
Allows folders in the file browser to display a cover image (e.g., `folder.jpg`) instead of the generic folder icon.

📂 [View Code](/2-browser-folder-cover.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Confirm First Time Opening</b></summary>
Adds a confirmation dialog or prompt when opening a book for the very first time, preventing accidental opens.

📂 [View Code](/2-confirm-first-open.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Cover Browser Mosaic Stretched</b></summary>
Modifies the Mosaic grid view to stretch cover images to fill the entire tile area, removing whitespace.

📂 [View Code](/2-CoverBrowserMosaicStretched.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Dynamic Mosaic Layout</b></summary>
Adjusts the number of columns and rows in the Mosaic view dynamically based on the device orientation or screen size.

📂 [View Code](/2-dynamic-mosaic-layout.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Filemanager Title Bar</b></summary>
Customizes the appearance or contents of the top title bar when navigating the file manager.

📂 [View Code](/2-filemanager-titlebar.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>New Cover Progress Bar</b></summary>
Replaces the standard progress bar with a customized "MM" style version, likely cleaner or thinner.

📂 [View Code](/2-MM-New-progress-bar.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>New Cover Status Icons</b></summary>
Updates the system status bar icons (battery, wifi, light) with a new custom icon set.

📂 [View Code](/2-MM-New-status-icons.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Cover Total Pages Badge</b></summary>
Overlays a badge on book covers in the library view showing the total page count.

📂 [View Code](/2-MM-pages-badge.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>New Cover Progress Badge</b></summary>
Overlays a small badge on book covers displaying the current reading percentage.

📂 [View Code](/2-MM-progress-badge.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Series Indicator</b></summary>
Adds visual indicators or numbering to covers to clearly show series order information.

📂 [View Code](/2-MM-series-indicator.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Browser Up Folder</b></summary>
Customizes the "Up Directory" (..) folder icon or behavior in the file browser.

📂 [View Code](/2-browser-up-folder.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Custom Underline Container (Last Focus)</b></summary>
Modifies the container logic for underlines, likely adjusting thickness or style for links/highlights.

📂 [View Code](/2--custom-underlinecontainer.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Disable Top Menu Zones</b></summary>
Disables specific touch zones associated with the top menu to prevent accidental taps.

📂 [View Code](/2-disable-top-menu-zones.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Menu Size</b></summary>
Provides options to adjust the global scaling or font size of the main menu interface.

📂 [View Code](/2-menu-size.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>New Cover Collections Badge (Star)</b></summary>
Adds a star icon to books in the browser to indicate they belong to a collection.

📂 [View Code](/2-MM-collections-star.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Rounded Corner Covers</b></summary>
Applies a border-radius to cover thumbnails, giving them rounded corners in the browser.

📂 [View Code](/2-MM--rounded-covers.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Change UI Font</b></summary>
Overrides the default system UI font with a custom user-defined font.

📂 [View Code](/2--ui-font.lua)

![Screenshot Description](link-to-your-image.png)
	</details>
</details>

<hr>
<details open>
<summary><h2>For the READER</h2></summary>
 <p><i>These patches are applied to the Reader</i></p>
 
<details>
	<summary><b>Reading Insights popup</b></summary>
Adds a popup feature that displays detailed insights about your reading session.

📂 [View Code](/2-reading-insights-popup.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Better Compact Status Bar</b></summary>
A compact layout for the status bar designed to maximize reading space while keeping info visible.

📂 [View Code](/2-statusbar-better-compact.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>2-custom-highligh-colors</b></summary>
Allows the user to define custom hex codes for text highlight colors.

📂 [View Code](/2-custom-highligh-colors.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Customise Progress Bar Colour gui</b></summary>
Adds a GUI menu option to easily change the color of the reading progress bar.

📂 [View Code](/2-customise-progress-bar-colour-gui.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Bigger Dog-ear (corner bookmark)</b></summary>
Increases the visual size of the "dogear" triangle used to mark pages.

📂 [View Code](/2-dogear-big.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Show Chapters in Highlights</b></summary>
Updates the highlight browser to display the chapter name alongside the highlighted text.

📂 [View Code](/2-highlights-show-chapters.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Mini-receipt Patch</b></summary>
A composite patch that creates a "mini receipt" style layout, likely combining progress bars and footer stats into a unified compact view.

📂 [View Code](/2-mini-receipt-frankenpatch.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Reader Header Print-edition</b></summary>
Modifies the reader header layout to resemble a print edition, possibly showing header text or page numbers differently.

📂 [View Code](/2--reader-header-print-edition.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Reading Stats popup</b></summary>
Enables a popup that displays current reading statistics such as speed and estimated time left.

📂 [View Code](/2-reading-stats-popup.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Reference Pages Counter</b></summary>
Forces the display of the reference (real) page count instead of the calculated screen count where available.

📂 [View Code](/2-reference-page-count.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Statusbar Thin Chapter</b></summary>
A variation of the status bar that is thinner and focuses on displaying chapter progress.

📂 [View Code](/2-statusbar-thin-chapter.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Vocabulary Builder Button</b></summary>
Adds a button to the reader interface for quickly adding words to the Vocabulary Builder.

📂 [View Code](/2-vocabulary-builder-button.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Double Progress Bar</b></summary>
Displays two concurrent progress bars, typically one for chapter progress and one for overall book progress.

📂 [View Code](/2-Double-progress-bar.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Set Translation Language per-document</b></summary>
Allows the translation target language to be saved specifically for each document rather than globally.

📂 [View Code](/2-set-translation-language-per-document.lua)

![Screenshot Description](link-to-your-image.png)
	</details>

<details>
	<summary><b>Book Title in TOC</b></summary>
Tweaks the display of titles within the Table of Contents, possibly adjusting truncation or font style.

📂 [View Code](/2-TOC-title-patch.lua)

![Screenshot Description](link-to-your-image.png)
	</details>
</details>
