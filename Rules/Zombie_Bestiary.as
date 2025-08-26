//TODO (check other todos throughout this file too)
// add back button to zombie bestiary main menu that goes back to the scoreboard
//  possibly redo zombie_scoreboard if it's too hard to add interactions
//  replace every occurance of "bestiary" verbiage with "bestiary"
//  may need translations since we are doing that elsewhere
// ZOMBIE DISCOVERY SYSTEM
//  icons are "?" until discovered, making them unclickable. 
//      build framework for saving unlocked zombies and displaying them. Brysen will implement conditions

#include "EasyUI.as"
#define CLIENT_ONLY

EasyUI@ ui;
//todo put this stuff in a namespace
MenuItem@[] bestiaryMenuItems;

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
    CRules@ rules;

    BackButtonReleaseHandler(List@ currentPage, List@ menuContainer)
    {
        @this.currentPage = currentPage;
        @this.menuContainer = menuContainer;
    }

    BackButtonReleaseHandler(CRules@ rules, List@ currentPage)
    {
        @this.currentPage = currentPage;
        @this.rules = rules;
    }

    void Handle()
    {
        if (currentPage !is null)
        {
            currentPage.SetVisible(false);

            if (menuContainer !is null)
            {
                menuContainer.SetVisible(true);
            }
            else if (rules !is null)
            {
                rules.set_bool("show_gamehelp", true);
            }
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

Pane@ createPage(CRules@ rules, EasyUI@ ui, List@ menuContainer, string titleText, string descriptionText, string texture, Vec2f frameDim=Vec2f(32.0, 32.0), uint frameIndex=0)
{
    Pane@ page = StandardPane(ui, StandardPaneType::Window);
    List@ header = createHeader(rules, titleText, page, menuContainer);

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
    icon.SetAlignment(1.0f, 0.0f);
    icon.SetMargin(10, 10);

    List@ pageContent = StandardList();
    pageContent.AddComponent(description);
    pageContent.AddComponent(icon);
    pageContent.SetCellWrap(2);
    pageContent.SetStretchRatio(1.0f, 1.0f);

    page.AddComponent(header);
    page.AddComponent(pageContent);
    page.SetMaxSize(512, 512);
    page.SetMinSize(512, 512);
    page.SetAlignment(0.5f, 0.5f);
    page.SetPadding(50, 50);
    page.SetRowSizes({0.2f, 0.8f});
    // page.SetRowSizes([0, 1]);
    // page.SetSpacing(0, 10);
    page.SetVisible(false);

    return page;
}

void addBestiaryMenuItem(CRules@ rules, EasyUI@ ui, List@ menuContainer, List@ menu, string titleText, string descriptionText, string texture, Vec2f frameDim=Vec2f(32.0, 32.0), uint frameIndex=0)
{
    // TODO: fix text
    Pane@ page = createPage(rules, ui, menuContainer, titleText, descriptionText, texture, frameDim, frameIndex);
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
    
    bestiaryMenuItems.push_back(menuItem);

    menu.AddComponent(menuItem);
}

List@ createHeader(CRules@ rules, string titleText, List@ listClose, List@ listBack = null, bool mainMenu = false)
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
    closeButton.AddEventListener(Event::Release, CloseButtonReleaseHandler(listClose));

    Label@ label = StandardLabel();
    label.SetText(titleText);
    label.SetColor(color_black);
    label.SetAlignment(0.5f, 0.0f);
    label.SetFont("big font");

    List@ title = StandardList();
    title.SetAlignment(0.5f, 0.0f);
    // title.SetStretchRatio(1.0f, 1.0f);
    title.AddComponent(label);
    // title.SetMargin(0, 10);

    if (listBack !is null || mainMenu)
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

        if (mainMenu)
        {
            backButton.AddEventListener(Event::Release, BackButtonReleaseHandler(rules, listClose));
        }
        else
        {
            backButton.AddEventListener(Event::Release, BackButtonReleaseHandler(listClose, listBack));
        }

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

StandardPane@ createBestiaryMainPage(CRules@ rules, EasyUI@ ui)
{   
    /*** MENU (ICON BUTTONS) ***/
    // Pane@ menu = StandardPane(ui, StandardPaneType::Window);
    List@ menu = StandardList();
    menu.SetAlignment(0.5f, 0.0f);
    menu.SetStretchRatio(1.0f, 1.0f);
    menu.SetCellWrap(4);
    menu.SetPadding(50, 50);
    menu.SetMargin(0, 10);

    //TODO rename menuContainer or menu so it makes more sense
    /*** MENU CONTAINER THAT HOLDS ALL COMPONENTS ***/
    StandardPane@ menuContainer = StandardPane(ui, StandardPaneType::Window);
    List@ header = createHeader(rules, "Bestiary", menuContainer, null, true);
    header.SetPadding(50, 0);

    menuContainer.SetStretchRatio(1.0f, 1.0f);
    menuContainer.SetMaxSize(512, 512);
    menuContainer.SetMinSize(512, 512);
    menuContainer.SetAlignment(0.5f, 0.5f);
    menuContainer.SetPadding(0, 25);
    menuContainer.AddComponent(header);
    menuContainer.AddComponent(menu);

    addBestiaryMenuItem(rules, ui, menuContainer, menu, "Greg", "Greg Description", "Zombies/Greg/Greg.png");
    addBestiaryMenuItem(rules, ui, menuContainer, menu, "Horror", "Horror Description", "Zombies/Horror/Horror.png");
    addBestiaryMenuItem(rules, ui, menuContainer, menu, "Skelepede", "Skelepede Description", "Zombies/Skelepede/Skelepede.png", Vec2f(25.0, 25.0));
    addBestiaryMenuItem(rules, ui, menuContainer, menu, "Skeleton", "Skeleton Description", "Zombies/Skeleton/Skeleton.png", Vec2f(25.0, 25.0));
    addBestiaryMenuItem(rules, ui, menuContainer, menu, "Wraith", "Wraith Description", "Zombies/Wraith/Wraith.png");
    addBestiaryMenuItem(rules, ui, menuContainer, menu, "Zombie", "Zombie Description", "Zombies/Zombie/Zombie.png", Vec2f(25.0, 25.0));
    addBestiaryMenuItem(rules, ui, menuContainer, menu, "Zombie Knight", "Zombie Knight Description", "Zombies/ZombieKnight/ZombieKnight.png");
    
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
    StandardPane@ menuContainer = createBestiaryMainPage(this, ui);
    menuContainer.SetVisible(false);
    // Pane@ menu = cast<Pane>(menuContainer.getComponents()[1]);
    this.set("menuContainer", @menuContainer);
}

void onTick(CRules@ this)
{
    ui.Update();
}

void onRender(CRules@ this)
{
    if (ui !is null)
    {
        ui.Render();
    }
    // ui.Debug(getControls().isKeyPressed(KEY_LSHIFT));
}