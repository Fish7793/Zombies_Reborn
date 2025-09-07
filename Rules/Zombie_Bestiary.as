//TODO: need better descriptions
#include "EasyUI.as"
#define CLIENT_ONLY

EasyUI@ ui;
BestiaryMenuItem@[] bestiaryMenuItems;
const Vec2f menuItemDim(128.0, 128.0);

class MenuButtonReleaseHandler : EventHandler
{
    CRules@ rules;
    List@ menuContainer;
    Pane@ page;
    string name;

    MenuButtonReleaseHandler(CRules@ otherRules, List@ otherMenuContainer, Pane@ otherPage, string otherName)
    {
        @rules = otherRules;
        @menuContainer = otherMenuContainer;
        @page = otherPage;
        name = otherName;
    }

    void Handle()
    {
        const bool discovered = rules.get_bool(name + "_discovered");

        if (discovered)
        {
            if (menuContainer !is null)
            {
                menuContainer.SetVisible(false);
            }
            page.SetVisible(true);
        }
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

class BestiaryMenuItemVisibilityHandler : EventHandler
{
    BestiaryMenuItem@ menuItem;

    BestiaryMenuItemVisibilityHandler(BestiaryMenuItem@ otherMenuItem)
    {
        @menuItem = otherMenuItem;
    }

    void Handle()
    {
        menuItem.updateButtonIcon();
    }
}

class BestiaryMenuItem : StandardPane
{
    CRules@ rules;
    Button@ button;
    string name;
    Icon@ icon;
    Icon@ discoveryIcon;

    BestiaryMenuItem(CRules@ otherRules, EasyUI@ ui, string otherName, List@ menuContainer, Pane@ page, Icon@ menuIcon)
    {
        super(ui);
        @rules = otherRules;
        name = otherName;
        @icon = menuIcon;
        @button = StandardButton(ui);
        @discoveryIcon = createBestiaryMenuIcon("InteractionIcons.png", Vec2f(32.0f, 32.0f), 14);
        updateButtonIcon();
        button.AddEventListener(Event::Release, MenuButtonReleaseHandler(rules, menuContainer, page, name));
        this.AddComponent(button);
    }

    void updateButtonIcon()
    {
        const bool discovered = rules.get_bool(name + "_discovered");
        Component@[] components;
        button.SetComponents(components);
        
        if (discovered)
        {
            button.AddComponent(icon);
        }
        else
        {
            button.AddComponent(discoveryIcon);
        }
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
    page.SetVisible(false);

    return page;
}

Icon@ createBestiaryMenuIcon(string texture, Vec2f frameDim, uint frameIndex)
{
    Icon@ menuIcon = StandardIcon();
    menuIcon.SetTexture(texture);
    menuIcon.SetMinSize(menuItemDim.x, menuItemDim.y);
    menuIcon.SetMaxSize(menuItemDim.x, menuItemDim.y);
    menuIcon.SetStretchRatio(1.0, 1.0);
    menuIcon.SetFrameDim(frameDim.x, frameDim.y);
    menuIcon.SetFrameIndex(frameIndex);
    menuIcon.SetFixedAspectRatio(false);

    return menuIcon;
}

void addBestiaryMenuItem(CRules@ rules, EasyUI@ ui, List@ menuContainer, List@ menu, string name, string descriptionText, string texture, Vec2f frameDim=Vec2f(32.0, 32.0), uint frameIndex=0)
{
    string titleText = name.substr(0, 1).toUpper() + name.substr(1).toLower();
    Pane@ page = createPage(rules, ui, menuContainer, titleText, descriptionText, texture, frameDim, frameIndex);
    ui.AddComponent(page);

    Icon@ menuIcon = createBestiaryMenuIcon(texture, frameDim, frameIndex);

    BestiaryMenuItem@ menuItem = BestiaryMenuItem(rules, ui, name, menuContainer, page, menuIcon);
    menuItem.SetMinSize(menuItemDim.x, menuItemDim.y);
    menuItem.SetMaxSize(menuItemDim.x, menuItemDim.y);
    menuItem.SetMargin(10, 10);
    menuContainer.AddEventListener(Event::Visibility, BestiaryMenuItemVisibilityHandler(menuItem));
    
    bestiaryMenuItems.push_back(menuItem);

    menu.AddComponent(menuItem);
}

List@ createHeader(CRules@ rules, string titleText, List@ listClose, List@ listBack = null, bool mainMenu = false)
{
    List@ header = StandardList();
    const Vec2f textureDim(32.0f, 32.0f);

    Icon@ closeButtonIcon = StandardIcon();
    closeButtonIcon.SetTexture("MenuItems.png");
    closeButtonIcon.SetMinSize(textureDim.x, textureDim.y);
    closeButtonIcon.SetMaxSize(textureDim.x, textureDim.y);
    closeButtonIcon.SetStretchRatio(1.0, 1.0);
    closeButtonIcon.SetFrameDim(textureDim.x, textureDim.y);
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
    title.AddComponent(label);

    if (listBack !is null || mainMenu)
    {
        header.SetCellWrap(3);

        Icon@ backButtonIcon = StandardIcon();
        backButtonIcon.SetTexture("MenuItems.png");
        backButtonIcon.SetMinSize(textureDim.x, textureDim.y);
        backButtonIcon.SetMaxSize(textureDim.x, textureDim.y);
        backButtonIcon.SetStretchRatio(1.0, 1.0);
        backButtonIcon.SetFrameDim(textureDim.x, textureDim.y);
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
    List@ menu = StandardList();
    menu.SetAlignment(0.5f, 0.0f);
    menu.SetStretchRatio(1.0f, 1.0f);
    menu.SetCellWrap(4);
    menu.SetPadding(50, 50);
    menu.SetMargin(0, 10);

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
    this.set("bestiaryMenuContainer", @menuContainer);
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