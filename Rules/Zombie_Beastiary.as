//TODO (check other todos throughout this file too)
//  change spacing between header and page content on pages, so that the page content takes up more room
//      possibly add scrolling
//  add a back button on pages to go back to main menu
//  add button to zombie_scoreboard (opened with backspace) that holds the bestiary button
//      either make bestiary overlap the scoreboard, or close the scoreboard and add back button to the bestiary
//  possibly redo zombie_scoreboard if it's too hard to add interactions
//  replace every occurance of "beastiary" verbiage with "bestiary"
//  may need translations since we are doing that elsewhere
// ZOMBIE DISCOVERY SYSTEM
//  icons are "?" until discovered, making them unclickable. 
//      build framework for saving unlocked zombies and displaying them. Brysen will implement conditions

#include "EasyUI.as"
#define CLIENT_ONLY

EasyUI@ ui;
//todo put this stuff in a namespace
MenuItem@[] beastiaryMenuItems;

class MenuButtonReleaseHandler : EventHandler
{
    List@ menuContainer;
    Pane@ page;

    MenuButtonReleaseHandler(List@ otherMenuContainer, Pane@ otherPage)
    {
        @menuContainer = otherMenuContainer;
        @page = otherPage;
    }

    void Handle()
    {
        if (menuContainer !is null)
        {
            menuContainer.SetVisible(false);
        }
        page.SetVisible(true);
    }
}

class CloseButtonReleaseHandler : EventHandler
{
    List@ list;

    CloseButtonReleaseHandler(List@ otherList)
    {
        @list = otherList;
    }

    void Handle()
    {
        if (list !is null)
        {
            list.SetVisible(false);
        }
    }
}

class BackButtonReleaseHandler : EventHandler
{
    List@ currentPage;
    List@ menuContainer;

    BackButtonReleaseHandler(List@ currentPage, List@ menuContainer)
    {
        @this.currentPage = currentPage;
        @this.menuContainer = menuContainer;
    }

    void Handle()
    {
        if (currentPage !is null && menuContainer !is null)
        {
            print("HANDLE BACK BUTTON");
            currentPage.SetVisible(false);
            menuContainer.SetVisible(true);
        }
        else {
            print("CURRENT PAGE IS NULL OR MENU CONTAINER IS NULL");
        }
    }
}

//TODO: get rid of MenuItem and replace it with StandardPane
class MenuItem : StandardPane
{
    //todo remove these as members if not needed, maybe handle AddEventListener outside the class
    Pane@ page;
    Button@ button;

    MenuItem(EasyUI@ ui, List@ menuContainer, Pane@ otherPage, Button@ otherButton)
    {
        super(ui);
        @page = @otherPage;
        @button = @otherButton;
        button.AddEventListener(Event::Release, MenuButtonReleaseHandler(menuContainer, otherPage));
    }
}

Pane@ createPage(EasyUI@ ui, List@ menuContainer, string titleText, string descriptionText, string texture, Vec2f frameDim=Vec2f(32.0, 32.0), uint frameIndex=0)
{
    Pane@ page = StandardPane(ui, StandardPaneType::Window);
    List@ header = createHeader(titleText, page, menuContainer);
    Label@ title = StandardLabel();
    title.SetText(titleText);
    title.SetMargin(0, 10);
    title.SetAlignment(0.5f, 0.0f);

    Label@ description = StandardLabel();
    description.SetText(descriptionText);
    description.SetMargin(10, 10);

    Vec2f iconDim(128.0, 128.0);
    Icon@ icon = StandardIcon();
    icon.SetTexture(texture);
    icon.SetMinSize(iconDim.x, iconDim.y);
    icon.SetMaxSize(iconDim.x, iconDim.y);
    icon.SetStretchRatio(1.0, 1.0);
    icon.SetFrameDim(frameDim.x, frameDim.y);
    icon.SetFrameIndex(frameIndex);
    icon.SetFixedAspectRatio(false);
    icon.SetMargin(10, 10);

    List@ descriptionIcon = StandardList();
    descriptionIcon.AddComponent(description);
    descriptionIcon.AddComponent(icon);
    descriptionIcon.SetCellWrap(2);

    page.AddComponent(header);
    page.AddComponent(descriptionIcon);
    page.SetMaxSize(512, 512);
    page.SetMinSize(512, 512);
    page.SetAlignment(0.5f, 0.5f);
    page.SetPadding(50, 50);
    page.SetVisible(false);

    return page;
}

void addBeastiaryMenuItem(EasyUI@ ui, List@ menuContainer, Pane@ menu, string texture, Vec2f frameDim=Vec2f(32.0, 32.0), uint frameIndex=0)
{
    // TODO: fix text
    // Page@ page = Page(ui, texture, texture, texture);
    Pane@ page = createPage(ui, menuContainer, texture, texture, texture);
    ui.AddComponent(page);

    Vec2f menuItemDim(128.0, 128.0);

    Icon@ menuIcon = StandardIcon();
    menuIcon.SetTexture(texture);
    menuIcon.SetMinSize(menuItemDim.x, menuItemDim.y);
    menuIcon.SetMaxSize(menuItemDim.x, menuItemDim.y);
    menuIcon.SetStretchRatio(1.0, 1.0);
    menuIcon.SetFrameDim(frameDim.x, frameDim.y);
    menuIcon.SetFrameIndex(frameIndex);
    menuIcon.SetFixedAspectRatio(false);

    Button@ menuButton = StandardButton(ui);
    menuButton.AddComponent(menuIcon);

    MenuItem@ menuItem = MenuItem(ui, menuContainer, page, menuButton);
    menuItem.SetMinSize(menuItemDim.x, menuItemDim.y);
    menuItem.SetMaxSize(menuItemDim.x, menuItemDim.y);
    menuItem.SetMargin(10, 10);
    menuItem.AddComponent(menuButton);
    
    beastiaryMenuItems.push_back(menuItem);

    menu.AddComponent(menuItem);
}

List@ createHeader(string titleText, List@ listToClose, List@ menuContainer = null)
{
    List@ header = StandardList();
    Vec2f menuItemDim(32.0f, 32.0f);

    //TODO create common function to handle creating the buttons to reduce repetitive code
    Icon@ closeButtonIcon = StandardIcon();
    closeButtonIcon.SetTexture("MenuItems.png");
    closeButtonIcon.SetMinSize(menuItemDim.x, menuItemDim.y);
    closeButtonIcon.SetMaxSize(menuItemDim.x, menuItemDim.y);
    closeButtonIcon.SetStretchRatio(1.0, 1.0);
    closeButtonIcon.SetFrameDim(menuItemDim.x, menuItemDim.y);
    closeButtonIcon.SetFrameIndex(29);
    closeButtonIcon.SetFixedAspectRatio(false);

    Button@ closeButton = StandardButton(ui);
    closeButton.AddComponent(closeButtonIcon);
    closeButton.SetAlignment(1.0f, 0.0f);
    closeButton.AddEventListener(Event::Release, CloseButtonReleaseHandler(listToClose));

    Label@ label = StandardLabel();
    label.SetText(titleText);
    label.SetColor(color_black);
    label.SetAlignment(0.5f, 0.0f);

    List@ title = StandardList();
    title.SetAlignment(0.5f, 0.0f);
    // title.SetStretchRatio(1.0f, 1.0f);
    title.AddComponent(label);
    // title.SetMargin(0, 10);

    if (menuContainer !is null)
    {
        header.SetCellWrap(3);

        Icon@ backButtonIcon = StandardIcon();
        backButtonIcon.SetTexture("MenuItems.png");
        backButtonIcon.SetMinSize(menuItemDim.x, menuItemDim.y);
        backButtonIcon.SetMaxSize(menuItemDim.x, menuItemDim.y);
        backButtonIcon.SetStretchRatio(1.0, 1.0);
        backButtonIcon.SetFrameDim(menuItemDim.x, menuItemDim.y);
        backButtonIcon.SetFrameIndex(2);
        backButtonIcon.SetFixedAspectRatio(false);
    
        Button@ backButton = StandardButton(ui);
        backButton.AddComponent(backButtonIcon);
        backButton.SetAlignment(1.0f, 0.0f);
        backButton.AddEventListener(Event::Release, BackButtonReleaseHandler(listToClose, menuContainer));

        header.AddComponent(backButton);
    }
    else
    {
        header.SetCellWrap(2);
    }
    
    header.AddComponent(title);
    header.AddComponent(closeButton);
    header.SetStretchRatio(1.0f, 0.0f);
    header.SetAlignment(0.5f, 0.0f);

    return header;
}

List@ createBeastiaryMainPage(EasyUI@ ui)
{   
    //TODO: make everything a Page, to keep things consistent and easier
    /*** MENU (ICON BUTTONS) ***/
    Pane@ menu = StandardPane(ui, StandardPaneType::Window);
    menu.SetAlignment(0.5f, 0.0f);
    menu.SetStretchRatio(1.0f, 1.0f);
    menu.SetCellWrap(4);
    menu.SetPadding(50, 50);
    menu.SetMargin(0, 10);

    //TODO rename menuContainer or menu so it makes more sense
    /*** MENU CONTAINER THAT HOLDS ALL COMPONENTS ***/
    List@ menuContainer = StandardList();
    List@ header = createHeader("Beastiary", menuContainer);

    menuContainer.SetStretchRatio(1.0f, 1.0f);
    menuContainer.SetMaxSize(512, 512);
    menuContainer.SetMinSize(512, 512);
    menuContainer.SetAlignment(0.5f, 0.5f);
    menuContainer.SetPadding(0, 100);
    menuContainer.AddComponent(header);
    menuContainer.AddComponent(menu);

    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/Greg/Greg.png");
    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/Horror/Horror.png");
    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/Skelepede/Skelepede.png", Vec2f(25.0, 25.0));
    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/Skeleton/Skeleton.png", Vec2f(25.0, 25.0));
    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/Wraith/Wraith.png");
    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/Zombie/Zombie.png", Vec2f(25.0, 25.0));
    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/ZombieKnight/ZombieKnight.png");
    
    ui.AddComponent(menuContainer);
    return menuContainer;
}

void onInit(CRules@ this)
{
    onRestart(this);
}

void onRestart(CRules@ this)
{
    @ui = EasyUI();
    List@ menuContainer = createBeastiaryMainPage(ui);
    // Pane@ menu = cast<Pane>(menuContainer.getComponents()[1]);
}

void onTick(CRules@ this)
{
    ui.Update();
}

void onRender(CRules@ this)
{
    ui.Render();
    ui.Debug(getControls().isKeyPressed(KEY_LSHIFT));
}