//TODO (check other todos throughout this file too)
//  change spacing between header and page content on pages, so that the page content takes up more room. 
//      possibly add scrolling
//  add a back button on pages to go back to main menu
//  add a hotkey or button that opens the main menu
// ZOMBIE DISCOVERY SYSTEM
//  icons are a "?" until the zombie has been encountered (talk to brysen to figure out conditions) and the button is unclickable

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

class CloseReleaseHandler : EventHandler
{
    List@ list;

    CloseReleaseHandler(List@ otherList)
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

Pane@ createPage(EasyUI@ ui, string titleText, string descriptionText, string texture, Vec2f frameDim=Vec2f(32.0, 32.0), uint frameIndex=0)
{
    Pane@ page = StandardPane(ui, StandardPaneType::Window);
    List@ header = createHeader(titleText, page);
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
    // page.AddComponent(title);
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
    Pane@ page = createPage(ui, texture, texture, texture);
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

List@ createHeader(string titleText, List@ listToClose)
{
    Vec2f closeButtonDim(32.0f, 32.0f);

    Icon@ closeButtonIcon = StandardIcon();
    closeButtonIcon.SetTexture("MenuItems.png");
    closeButtonIcon.SetMinSize(closeButtonDim.x, closeButtonDim.y);
    closeButtonIcon.SetMaxSize(closeButtonDim.x, closeButtonDim.y);
    closeButtonIcon.SetStretchRatio(1.0, 1.0);
    closeButtonIcon.SetFrameDim(closeButtonDim.x, closeButtonDim.y);
    closeButtonIcon.SetFrameIndex(29);
    closeButtonIcon.SetFixedAspectRatio(false);

    Button@ closeButton = StandardButton(ui);
    closeButton.AddComponent(closeButtonIcon);
    closeButton.SetAlignment(1.0f, 0.0f);
    closeButton.AddEventListener(Event::Release, CloseReleaseHandler(listToClose));

    Label@ label = StandardLabel();
    label.SetText(titleText);
    label.SetColor(color_black);
    label.SetAlignment(0.5f, 0.0f);

    List@ title = StandardList();
    title.SetAlignment(1.0f, 0.0f);
    // title.SetStretchRatio(1.0f, 1.0f);
    title.AddComponent(label);
    // title.SetMargin(0, 10);

    List@ header = StandardList();
    //TODO: add back arrow button to header
    header.SetStretchRatio(1.0f, 0.0f);
    header.SetAlignment(0.5f, 0.0f);
    header.SetCellWrap(2);
    header.AddComponent(title);
    header.AddComponent(closeButton);

    return header;
}

List@ createBeastiaryMainPage(EasyUI@ ui)
{   
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